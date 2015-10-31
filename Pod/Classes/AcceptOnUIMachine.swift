import Stripe

@objc public protocol AcceptOnUIMachineDelegate {
    //Start-up
    optional func acceptOnUIMachineDidFailBegin(error: NSError)
    optional func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions)
    
    //Credit-card form
    optional func acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String)
    optional func acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String)
    optional func acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName(name: String)
    optional func acceptOnUIMachineCreditCardTypeDidChange(type: String)
    
    //Mid-cycle
    optional func acceptOnUIMachinePaymentIsProcessing(paymentType: String)
    optional func acceptOnUIMachinePaymentDidAbortPaymentMethodWithName(name: String)
    optional func acceptOnUIMachinePaymentErrorWithMessage(message: String)
    optional func acceptOnUIMachinePaymentDidSucceed()
    
    //Spec related
    optional func acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName(name: String, withValue value: String)  //Field updated, no validation error
}

//Contains error codes for AcceptOnUIMachine & convenience methods
public struct AcceptOnUIMachineError {
    public static let domain = "com.accepton.UIMachine.error"
    
    public enum Code: Int {
        case DeveloperError = -5555
    }
    
    //Creates an NSError given the error code and failure reason
    public static func errorWithCode(code: Code, failureReason: String) -> NSError {
        let info = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: domain, code: code.rawValue, userInfo: info)
    }
}

public class AcceptOnUIMachineFormOptions : NSObject {
    let token: AcceptOnAPITransactionToken!
    let paymentMethods: AcceptOnAPIPaymentMethodsInfo!
    public var itemDescription: String {
        return token.desc
    }
    
    public var amountInCents: Int {
        return token.amountInCents
    }
    
    /* The different sections available, credit-card, paypal, etc. */
    public var hasCreditCardForm: Bool {
        return paymentMethods.supportsCreditCard
    }
    
    public var hasPaypalButton: Bool {
        return paymentMethods.supportsPaypal
    }
    
    public var hasApplePay: Bool {
        return paymentMethods.supportsApplePay
    }
    
    //Converts amountInCents into a $xx.xx style string.  E.g. 349 -> $3.49
    public var uiAmount: String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.locale = NSLocale(localeIdentifier: "en_US")
        return formatter.stringFromNumber(Double(amountInCents) / 100.0) ?? "<error>"
    }
    
    public init(token: AcceptOnAPITransactionToken, paymentMethods: AcceptOnAPIPaymentMethodsInfo) {
        self.token = token
        self.paymentMethods = paymentMethods
        super.init()
    }
}

enum AcceptOnUIMachineState {
    case Initialized      //begin has not been called
    case BeginWasCalled   //In the middle of the begin
    case PaymentForm      //begin succeeded
    case WaitingForPaypal //Paypal dialog is open
    case PaymentComplete  //Payment has completed
}

public class AcceptOnUIMachine: NSObject, AcceptOnUIMachinePaypalDriverDelegate {
    /* ######################################################################################### */
    /* Constructors & Members (Stage I)                                                          */
    /* ######################################################################################### */
    public convenience init(publicKey: String) {
        self.init(api: AcceptOnAPI(publicKey: publicKey))
    }
    
    public convenience init(secretKey: String) {
        self.init(api: AcceptOnAPI(secretKey: secretKey))
    }
    
    let api: AcceptOnAPI!                          //This is the networking API object
    public init(api: AcceptOnAPI) {
        self.api = api
    }
    
    //Controls the state transitions
    var state: AcceptOnUIMachineState {
        get {
            return _state
        }
        
        set (newState) {
            _state = newState
        }
    }
    var _state: AcceptOnUIMachineState = .Initialized
    
    //This is typically the vc that created us
    public weak var delegate: AcceptOnUIMachineDelegate?

    /* ######################################################################################### */
    /* Stage II Initializers                                                                     */
    /* ######################################################################################### */
    //Signal from controller that we are ready to fetch data on the form configuration
    //and signal to the controller the didLoadFormWithConfig event for the given transaction
    //request
    var tokenObject: AcceptOnAPITransactionToken? //Transaction token that was created during beginForItemWithDescription for the given parameters
    var amountInCents: Int?                             //Amount in cents of this transaction
    var itemDescription: String?                        //Description of this transaction
    var paymentMethods: AcceptOnAPIPaymentMethodsInfo?  //Retrieved by the AcceptOnAPI containing the form configuration (payment types accepted)
    public func beginForItemWithDescription(description: String, forAmountInCents amountInCents: Int) {
        //Prevent race-conditions on didBegin check
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            //Can only be called at the start once.  It's a stage II initializer
            if (self?._state != .Initialized) {
                self?.delegate?.acceptOnUIMachineDidFailBegin?(AcceptOnUIMachineError.errorWithCode(.DeveloperError, failureReason: "You already called beginForItemWithDescription; this should have been called once at the start.  You will have to make a new AcceptOnUIMachine for a new form"))
                return
            }
            self?.state = .BeginWasCalled
            
            //Create a transaction token
            self?.api.createTransactionTokenWithDescription(description, forAmountInCents: amountInCents) { (tokenObject, error) -> () in
                if let error = error {
                    //Non-Recoverable, recreate UIMachine to start-over
                    self?.delegate?.acceptOnUIMachineDidFailBegin?(error)
                    return
                }
                
                self?.tokenObject = tokenObject
                self?.amountInCents = amountInCents
                self?.itemDescription = description
                
                //Request the form configuration
                self?.api.getAvailablePaymentMethodsForTransactionWithId(tokenObject!.id, completion: { (paymentMethods, error) -> () in
                    //Make sure we got back a response
                    if let error = error {
                        //Non-Recoverable, recreate UIMachine to start-over
                        self?.delegate?.acceptOnUIMachineDidFailBegin?(error)
                        return
                    }
                    
                    //Save the paymentMethods
                    self?.paymentMethods = paymentMethods!
                    
                    //Notify that we are loaded
                    self?.state = .PaymentForm
                    self?.postBegin()
                })
            }
        }
    }
    
    //Called at the end of the beginForItemWithDescription sequence. By now, we've
    //loaded the tokenId & paymentMethods.
    func postBegin() {
        //Get our form options
        let options = AcceptOnUIMachineFormOptions(token: self.tokenObject!, paymentMethods: self.paymentMethods!)
        
        //Signal that we should show the form
        self.delegate?.acceptOnUIMachineDidFinishBeginWithFormOptions?(options)
    }
    
    
    /* ######################################################################################### */
    /* Credit Card Form Specifics                                                                */
    /* ######################################################################################### */
    //User targets a credit-card field, or untargets a field. Field names
    //are specified in the example form in https://github.com/sotownsend/accepton-apple/blob/master/docs/AcceptOnUIMachine.md
    var _currentFocusedCreditCardFieldName: String?
    var currentFocusedCreditCardFieldName: String? {
        set (newFieldName) {
            //Validate the old field if it existed
            if let _currentFocusedCreditCardFieldName = _currentFocusedCreditCardFieldName {
                validateCreditCardFieldWithName(_currentFocusedCreditCardFieldName)
            }
            
            _currentFocusedCreditCardFieldName = newFieldName
        }
        
        get {
            return _currentFocusedCreditCardFieldName
        }
    }
    
    public func creditCardFieldDidFocusWithName(name: String) {
        guard state == .PaymentForm else { return }
        
        currentFocusedCreditCardFieldName = name
    }
    
    public func creditCardFieldDidLoseFocus() {
        guard _state == .PaymentForm else { return }
        
        currentFocusedCreditCardFieldName = nil
    }
    
    public func creditCardFieldWithName(name: String, didUpdateWithString string: String) {
        if (name == "email") { updateCreditCardEmailFieldWithString(string)}
        else if (name == "cardNum") { updateCreditCardCardNumFieldWithString(string)}
        else if (name == "expMonth") { updateCreditCardExpMonthFieldWithString(string)}
        else if (name == "expYear") { updateCreditCardExpYearFieldWithString(string)}
        else if (name == "security") { updateCreditCardSecurityFieldWithString(string)}
    }
    
    func validateCreditCardFieldWithName(name: String) {
        if (name == "email") { validateCreditCardEmailField() }
        else if (name == "cardNum") { validateCreditCardCardNumField() }
        else if (name == "expMonth") { validateCreditCardExpMonthField() }
        else if (name == "expYear") { validateCreditCardExpYearField() }
        else if (name == "security") { validateCreditCardSecurityField() }
    }
    
    public func creditCardReset() {
        _emailFieldValue = ""
        _cardNumFieldValue = ""
        _expMonthFieldValue = ""
        _expYearFieldValue = ""
        _securityFieldValue = ""
        _creditCardType = "unknown"
        
        emailFieldHasValidationError = false
        cardNumFieldHasValidationError = false
        expMonthFieldHasValidationError = false
        expYearFieldHasValidationError = false
        securityFieldHasValidationError = false
    }
    
    //Email field
    /////////////////////////////////////////////////////////////////////
    var _emailFieldValue: String?
    var emailFieldValue: String {
        get { return _emailFieldValue ?? "" }
        set { _emailFieldValue = newValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) }
    }
    var emailFieldHasValidationError: Bool = false
    
    func validateCreditCardEmailField() -> Bool {
        var errorStr: String? = nil
       
        if emailFieldValue == "" { errorStr = "Please enter an email" }
        else {
            let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
            let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            if emailTest.evaluateWithObject(emailFieldValue) != true {
                errorStr = "Please check your email"
            }
        }
    
        if let errorStr = errorStr {
            //We have a new validation error
            if (emailFieldHasValidationError == false) {
                delegate?.acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName?("email", withMessage: errorStr)
                emailFieldHasValidationError = true
            } else {
                //We still have a validation error
                delegate?.acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName?("email", withMessage: errorStr)
            }
        } else {
            //We no longer have a validation error
            if emailFieldHasValidationError == true {
                emailFieldHasValidationError = false
                delegate?.acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName?("email")
            }
            delegate?.acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName?("email", withValue: emailFieldValue)
        }
        return errorStr == nil ? true : false
    }
    
    func updateCreditCardEmailFieldWithString(string: String) {
        emailFieldValue = string
    }
    /////////////////////////////////////////////////////////////////////

    //cardNum field
    /////////////////////////////////////////////////////////////////////
    var _cardNumFieldValue: String?
    var _creditCardType: String = "unknown"
    var creditCardType: String {
        get {
            return _creditCardType
        }
        
        set {
            if newValue != _creditCardType {
                delegate?.acceptOnUIMachineCreditCardTypeDidChange?(newValue)
            }
            
            _creditCardType = newValue
        }
    }
    var cardNumFieldValue: String {
        get { return _cardNumFieldValue ?? "" }
        set { _cardNumFieldValue = newValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) }
    }
    var cardNumFieldHasValidationError: Bool = false
    
    func validateCreditCardCardNumField() -> Bool {
        var errorStr: String? = nil
       
        if cardNumFieldValue == "" { errorStr = "Please enter an card number" }
        else {
            let cardNumValidationState = STPCardValidator.validationStateForNumber(cardNumFieldValue, validatingCardBrand: true)
            if cardNumValidationState != .Valid {
                errorStr = "Please check your card number"
            }
        }
    
        if let errorStr = errorStr {
            //We have a new validation error
            if (cardNumFieldHasValidationError == false) {
                delegate?.acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName?("cardNum", withMessage: errorStr)
                cardNumFieldHasValidationError = true
            } else {
                //We still have a validation error
                delegate?.acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName?("cardNum", withMessage: errorStr)
            }
        } else {
            //We no longer have a validation error
            if cardNumFieldHasValidationError == true {
                cardNumFieldHasValidationError = false
                delegate?.acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName?("cardNum")
            }
            delegate?.acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName?("cardNum", withValue: cardNumFieldValue)
        }
        return errorStr == nil ? true : false
    }
    func updateCreditCardCardNumFieldWithString(string: String) {
        cardNumFieldValue = string
        
        let cardBrand = STPCardValidator.brandForNumber(string)
        switch (cardBrand) {
        case .Visa:
            creditCardType = "visa"
        case .Amex:
            creditCardType = "amex"
        case .Discover:
            creditCardType = "discover"
        case .MasterCard:
            creditCardType = "master_card"
        default:
            creditCardType = "unknown"
        }
    }
    /////////////////////////////////////////////////////////////////////

    //expMonth field
    /////////////////////////////////////////////////////////////////////
    var _expMonthFieldValue: String?
    var expMonthFieldValue: String? {
        get { return _expMonthFieldValue }
        set { _expMonthFieldValue = newValue?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) }
    }
    var expMonthFieldHasValidationError: Bool = false
    
    func validateCreditCardExpMonthField() -> Bool {
        var errorStr: String? = nil
       
        if expMonthFieldValue == "" { errorStr = "Please enter the expiration month" }
        else {
            let expMonthValidationState = STPCardValidator.validationStateForExpirationMonth(expMonthFieldValue ?? "<no month>")
            if expMonthValidationState != .Valid {
                errorStr = "Please check your card number"
            }
        }
    
        if let errorStr = errorStr {
            //We have a new validation error
            if (expMonthFieldHasValidationError == false) {
                delegate?.acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName?("expMonth", withMessage: errorStr)
                expMonthFieldHasValidationError = true
            } else {
                //We still have a validation error
                delegate?.acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName?("expMonth", withMessage: errorStr)
            }
        } else {
            //We no longer have a validation error
            if expMonthFieldHasValidationError == true {
                expMonthFieldHasValidationError = false
                delegate?.acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName?("expMonth")
            }
            delegate?.acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName?("expMonth", withValue: expMonthFieldValue ?? "<no month>")
        }

        return errorStr == nil ? true : false
    }
    func updateCreditCardExpMonthFieldWithString(string: String) {
        expMonthFieldValue = string
    }
    /////////////////////////////////////////////////////////////////////

    //expYear field
    /////////////////////////////////////////////////////////////////////
    var _expYearFieldValue: String?
    var expYearFieldValue: String {
        get { return _expYearFieldValue ?? "" }
        set { _expYearFieldValue = newValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) }
    }
    var expYearFieldHasValidationError: Bool = false
    
    func validateCreditCardExpYearField() -> Bool {
        var errorStr: String? = nil
       
        if expYearFieldValue == "" { errorStr = "Please enter the expiration year" }
        else {
            let expYearValidationState = STPCardValidator.validationStateForExpirationYear(expYearFieldValue, inMonth: expMonthFieldValue ?? "01")
            if expYearValidationState != .Valid {
                errorStr = "Please check your card number"
            }
        }
    
        if let errorStr = errorStr {
            //We have a new validation error
            if (expYearFieldHasValidationError == false) {
                delegate?.acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName?("expYear", withMessage: errorStr)
                expYearFieldHasValidationError = true
            } else {
                //We still have a validation error
                delegate?.acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName?("expYear", withMessage: errorStr)
            }
        } else {
            //We no longer have a validation error
            if expYearFieldHasValidationError == true {
                expYearFieldHasValidationError = false
                delegate?.acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName?("expYear")
            }
            delegate?.acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName?("expYear", withValue: expYearFieldValue)
        }
        return errorStr == nil ? true : false
    }
    func updateCreditCardExpYearFieldWithString(string: String) {
        expYearFieldValue = string
    }
    /////////////////////////////////////////////////////////////////////

    //security field
    /////////////////////////////////////////////////////////////////////
    var _securityFieldValue: String?
    var securityFieldValue: String {
        get { return _securityFieldValue ?? "" }
        set { _securityFieldValue = newValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) }
    }
    var securityFieldHasValidationError: Bool = false
    
    func validateCreditCardSecurityField() -> Bool {
        var errorStr: String? = nil
       
        if securityFieldValue == "" { errorStr = "Please enter the security code" }
        else {
            let securityValidationState = STPCardValidator.validationStateForCVC(securityFieldValue, cardBrand: STPCardValidator.brandForNumber(cardNumFieldValue))
            if securityValidationState != .Valid {
                errorStr = "Please check your security code"
            }
        }
    
        if let errorStr = errorStr {
            //We have a new validation error
            if (securityFieldHasValidationError == false) {
                delegate?.acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName?("security", withMessage: errorStr)
                securityFieldHasValidationError = true
            } else {
                //We still have a validation error
                delegate?.acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName?("security", withMessage: errorStr)
            }
        } else {
            //We no longer have a validation error
            if securityFieldHasValidationError == true {
                securityFieldHasValidationError = false
                delegate?.acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName?("security")
            }
            delegate?.acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName?("security", withValue: securityFieldValue)
        }
        return errorStr == nil ? true : false
    }
    func updateCreditCardSecurityFieldWithString(string: String) {
        securityFieldValue = string
    }
    /////////////////////////////////////////////////////////////////////

    //User hits the 'pay' button
    public func creditCardPayClicked() {
        //Don't use &&: optimizer might attempt short-circuit multi-line
        //statements and we want all these to execute at the same time
        let resEmail = validateCreditCardEmailField()
        let resCardNum = validateCreditCardCardNumField()
        let resCardExpMonth = validateCreditCardExpMonthField()
        let resCardExpYear = validateCreditCardExpYearField()
        let resCardSecurity = validateCreditCardSecurityField()

        if (resEmail && resCardNum && resCardExpMonth && resCardExpYear && resCardSecurity == true) {
            dispatch_async(dispatch_get_main_queue(), { [weak self] in
                self?.delegate?.acceptOnUIMachinePaymentIsProcessing?("credit_card")
            })
        }
    }
    
    /* ######################################################################################### */
    /* Paypal specifics                                                                          */
    /* ######################################################################################### */
    lazy var paypalDriver: AcceptOnUIMachinePaypalDriver = AcceptOnUIMachinePaypalDriver()
    public func paypalClicked() {
        if state != .PaymentForm { return }
        
        self.state = .WaitingForPaypal
        //Wait 1500ms so there is time to show something like a loading screen to the user
        let delay = Int64(1500) * Int64(NSEC_PER_MSEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, delay)
        dispatch_after(time, dispatch_get_main_queue()) { [weak self] in
            self?.paypalDriver.delegate = self
            self?.paypalDriver.beginPaypalTransactionWithAmountInCents(NSDecimalNumber(long: self!.amountInCents!), andDescription: self!.itemDescription!)
        }
        
        delegate?.acceptOnUIMachinePaymentIsProcessing?("paypal")
    }
    
    //AcceptOnUIMachinePaypalDriverDelegate Handlers
    func paypalTransactionDidFailWithMessage(message: String) {
        if state != .WaitingForPaypal { return }
        state = .PaymentForm
        
        delegate?.acceptOnUIMachinePaymentDidAbortPaymentMethodWithName?("paypal")
        delegate?.acceptOnUIMachinePaymentErrorWithMessage?(message)
    }
    
    func paypalTransactionDidSucceed() {
        //We could double charge if this goes catastrophically wrong, so let it
        //trigger the transaction completion under any conditions
//        if state != .WaitingForPaypal { return }
        
        state = .PaymentComplete
        delegate?.acceptOnUIMachinePaymentDidSucceed?()
    }
    
    func paypalTransactionDidCancel() {
        if state != .WaitingForPaypal { return }
        state = .PaymentForm
        
        delegate?.acceptOnUIMachinePaymentDidAbortPaymentMethodWithName?("paypal")
    }
}
