import StripePrivate

@objc public protocol AcceptOnUIMachineDelegate {
    //Start-up
    optional func acceptOnUIMachineDidFailBegin(error: NSError)
    optional func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions)
    
    //Credit-card form
    optional func acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String)
    optional func acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String)
    optional func acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName(name: String)
    optional func acceptOnUIMachineCreditCardTypeDidChange(type: String)
    optional func acceptOnUIMachineDidSetInitialFieldValueWithName(name: String, withValue value: String)
    
    //Mid-cycle
    optional func acceptOnUIMachinePaymentIsProcessing(paymentType: String)
    optional func acceptOnUIMachinePaymentDidAbortPaymentMethodWithName(name: String)
    optional func acceptOnUIMachinePaymentErrorWithMessage(message: String)
    optional func acceptOnUIMachinePaymentDidSucceedWithCharge(chargeInfo: [String:AnyObject])
    
    //Requests showing additional fields based on the requirements dictated by the userInfo structure. On as successful completion (i.e. wasCancelled is false)
    //the metadata returned is merged into the formOptions.metadata
    func acceptOnUIMachineDidRequestAdditionalUserInfo(userInfo: AcceptOnUIMachineOptionalUserInfo, completion: (wasCancelled: Bool, info: AcceptOnUIMachineExtraFieldsMetadataInfo?)->())
    
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
        return paymentMethods.supportsApplePay && AcceptOnUIMachineApplePayDriver.checkAvailability() != .NotSupported
    }
    
    //Converts amountInCents into a $xx.xx style string.  E.g. 349 -> $3.49
    public var uiAmount: String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.locale = NSLocale(localeIdentifier: "en_US")
        return formatter.stringFromNumber(Double(amountInCents) / 100.0) ?? "<error>"
    }
    
    public init(token: AcceptOnAPITransactionToken, paymentMethods: AcceptOnAPIPaymentMethodsInfo, userInfo: AcceptOnUIMachineOptionalUserInfo?=nil) {
        self.token = token
        self.paymentMethods = paymentMethods
        self.userInfo = userInfo
        super.init()
    }
    
    //Additional user information
    public var userInfo: AcceptOnUIMachineOptionalUserInfo?
    
    //Credit card transactions post the email & all fields of the credit-card
    public var creditCardParams: AcceptOnUIMachineCreditCardParams?
    
    //Extra information, either provided by the 'extra' enabled fields
    //or user added
    public var metadata: [String:AnyObject] = [:]
}

//Used to pass-around the credit-card form information to drivers
public struct AcceptOnUIMachineCreditCardParams {
    let number: String
    let expMonth: String
    let expYear: String
    let cvc: String
    let email: String
    
    init(number: String, expMonth: String, expYear: String, cvc: String, email: String) {
        self.number = number
        self.expMonth = expMonth
        self.expYear = expYear
        self.cvc = cvc
        self.email = email
    }
}

enum AcceptOnUIMachineState: String {
    case Initialized = "Initialized"                     //begin has not been called
    case BeginWasCalled = "BeginWasCalled"               //In the middle of the begin
    case PaymentForm = "PaymentForm"                     //begin succeeded
    case ExtraFields = "ExtraFields"                     //Showing extra fields dialog
    case WaitingForTransaction = "WaitingForTransaction" //In the middle of a transaction request (like apple-pay, credit-card, paypal, etc)
    case PaymentComplete = "PaymentComplete"             //Payment has completed
}

//Various informations about a user like email
//that can be used for things like pre-populating forms
@objc public class AcceptOnUIMachineOptionalUserInfo: NSObject {
    public override init() {}
    
    //--------------------------------------------------------------------------------
    //Autofill the user's email address
    //--------------------------------------------------------------------------------
    public var emailAutofillHint: String?
    
    //--------------------------------------------------------------------------------
    //Collect, and require, billing address information
    //--------------------------------------------------------------------------------
    public var requestsAndRequiresBillingAddress: Bool = false
    public var billingAddressAutofillHints: AcceptOnAPIAddress?
    
    //--------------------------------------------------------------------------------
    //Collect, and require, shipping information. For payment systems that require
    //that shipping costs be provided, such as apple-pay, we automatically
    //set these as "Shipping Included" and set the shipping fee to `$0` on
    //any necessary shipping information fields.
    //--------------------------------------------------------------------------------
    public var requestsAndRequiresShippingAddress: Bool = false
    public var shippingAddressAutofillHints: AcceptOnAPIAddress?
    
    //--------------------------------------------------------------------------------
    //Additional metadata to pass in, this will just be passed through to the final
    //output and placed into the metadata field
    //--------------------------------------------------------------------------------
    public var extraMetadata: [String:AnyObject]?
}

//Provided on completion of 'extra fields'
@objc public class AcceptOnUIMachineExtraFieldsMetadataInfo: NSObject {
    public override init() {}
    
    public var email: String?
    public var billingAddress: AcceptOnAPIAddress?
    public var shippingAddress: AcceptOnAPIAddress?
    public var billingSameAsShipping: Bool?
    
    func toDictionary() -> [String:AnyObject] {
        var out: [String:AnyObject] = [:]
        
        if let email = email {
            out["email"] = email
        }
        
        if let billingAddress = billingAddress {
            out["billing_address"] = billingAddress.toDictionary()
        }
        
        if let shippingAddress = shippingAddress {
            out["shipping_address"] = shippingAddress.toDictionary()
        }
        
        if let billingSameAsShipping = billingSameAsShipping {
            out["billing_same_as_shipping"] = billingSameAsShipping
        }
        
        return out
    }
}


public class AcceptOnUIMachine: NSObject, AcceptOnUIMachinePaymentDriverDelegate {
    /* ######################################################################################### */
    /* Constructors & Members (Stage I)                                                          */
    /* ######################################################################################### */
    var userInfo: AcceptOnUIMachineOptionalUserInfo?
    public convenience init(publicKey: String, isProduction: Bool, userInfo: AcceptOnUIMachineOptionalUserInfo? = nil) {
        self.init(api: AcceptOnAPI(publicKey: publicKey, isProduction: isProduction), userInfo: userInfo)
    }
    
    public convenience init(secretKey: String, isProduction: Bool, userInfo: AcceptOnUIMachineOptionalUserInfo? = nil) {
        self.init(api: AcceptOnAPI(secretKey: secretKey, isProduction: isProduction), userInfo: userInfo)
    }
    
    public var api: AcceptOnAPI                          //This is the networking API object
    public init(api: AcceptOnAPI, userInfo: AcceptOnUIMachineOptionalUserInfo? = nil) {
        self.api = api
        self.userInfo = userInfo
    }
    
    //Controls the state transitions
    var state: AcceptOnUIMachineState = .Initialized {
        didSet {
            self.stateInfo = nil
            GoogleAnalytics.trackPageNamed(state.rawValue)
        }
    }
    var stateInfo: Any?
    
    public var isProduction: Bool {
        return api.isProduction
    }
    
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
            if (self?.state != .Initialized) {
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
    var options: AcceptOnUIMachineFormOptions!
    func postBegin() {
        options = AcceptOnUIMachineFormOptions(token: self.tokenObject!, paymentMethods: self.paymentMethods!, userInfo: userInfo)
        
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
        guard state == .PaymentForm else { return }
        
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
    
    //Must be always called, will auto-fill out credit-card form with email if available
    public func didSwitchToCreditCardForm() {
        //If user info received email, update the email field
        if let email = self.userInfo?.emailAutofillHint {
            if self.delegate?.acceptOnUIMachineDidSetInitialFieldValueWithName != nil {
                self.delegate?.acceptOnUIMachineDidSetInitialFieldValueWithName!("email", withValue: email)
                updateCreditCardEmailFieldWithString(email)
                validateCreditCardEmailField()
            }
        }
        
    }
    
    //Optional, allows you to use on apps that contain a payment selection form
    public func didSwitchFromCreditCardForm() {
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
    //User hits the 'pay' button for the credit-card form
    public func creditCardPayClicked() {
        //startTransaction changes the state
        if state != .PaymentForm { return }
        
        //Don't use &&: optimizer might attempt short-circuit some
        //statements and we want all these to execute even if some fail
        let resEmail = validateCreditCardEmailField()
        let resCardNum = validateCreditCardCardNumField()
        let resCardExpMonth = validateCreditCardExpMonthField()
        let resCardExpYear = validateCreditCardExpYearField()
        let resCardSecurity = validateCreditCardSecurityField()

        //Are we good on all the validations?
        if (resEmail && resCardNum && resCardExpMonth && resCardExpYear && resCardSecurity == true) {
            self.delegate?.acceptOnUIMachinePaymentIsProcessing?("credit_card")
            
            //Create our helper struct to pass to our drivers
            let cardParams = AcceptOnUIMachineCreditCardParams(number: cardNumFieldValue, expMonth: expMonthFieldValue ?? "", expYear: expYearFieldValue, cvc: securityFieldValue, email: emailFieldValue)
            self.options!.creditCardParams = cardParams
            self.startTransactionWithDriverOfClass(AcceptOnUIMachineCreditCardDriver.self)
        }
    }
    
    /* ######################################################################################### */
    /* Paypal specifics                                                                          */
    /* ######################################################################################### */
    public func paypalClicked() {
        if state != .PaymentForm { return }
        
        //Wait 1.5 seconds so it has time to show a loading screen of sorts
        startTransactionWithDriverOfClass(AcceptOnUIMachinePayPalDriver.self, withDelay: 1.3)
    }
    
    /* ######################################################################################### */
    /* ApplePay specifics                                                                        */
    /* ######################################################################################### */
    public func applePayClicked() {
        if state != .PaymentForm { return }
        
        //Wait 1.5 seconds so it has time to show a loading screen of sorts
        startTransactionWithDriverOfClass(AcceptOnUIMachineApplePayDriver.self, withDelay: 1.3)
    }
    
    
   //-----------------------------------------------------------------------------------------------------
   //AcceptOnUIMachinePaymentDriverDelegate
   //-----------------------------------------------------------------------------------------------------
    func transactionDidCancelForDriver(driver: AcceptOnUIMachinePaymentDriver) {
        if state != .WaitingForTransaction { return }
        state = .PaymentForm
        
        delegate?.acceptOnUIMachinePaymentDidAbortPaymentMethodWithName?(driver.dynamicType.name)
    }
    
    func transactionDidFailForDriver(driver: AcceptOnUIMachinePaymentDriver, withMessage message: String) {
        if state != .WaitingForTransaction { return }
        state = .PaymentForm
        
        delegate?.acceptOnUIMachinePaymentDidAbortPaymentMethodWithName?(driver.dynamicType.name)
        delegate?.acceptOnUIMachinePaymentErrorWithMessage?(message)
    }
    
    func transactionDidSucceedForDriver(driver: AcceptOnUIMachinePaymentDriver, withChargeRes chargeRes: [String : AnyObject]) {
        state = .PaymentComplete
        
        delegate?.acceptOnUIMachinePaymentDidSucceedWithCharge?(chargeRes)
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Starts the transaction process for a driver
    //-----------------------------------------------------------------------------------------------------
    var activeDriver: AcceptOnUIMachinePaymentDriver!
    func startTransactionWithDriverOfClass(driverClass: AcceptOnUIMachinePaymentDriver.Type, withDelay delay: Double=0.0) {
        self.delegate?.acceptOnUIMachinePaymentIsProcessing?(driverClass.name)
        
        //Switch to 'extra fields', store the parameters to use when extra fields completes
        self.state = .ExtraFields
        
        let block = { [weak self] in
            if self == nil { return }
            
            if self?.state != .ExtraFields { return }
            self?.displayExtraFieldsIfNecessaryAndCompleteByTransactingWithDriver(driverClass)  //Loads the 'metadata' information
        }
        
        if delay == 0 {
            block()
        } else {
            let delay = Int64(delay*1000) * Int64(NSEC_PER_MSEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, delay)
            dispatch_after(time, dispatch_get_main_queue()) {
                block()
            }
        }
    }
    
    //Show extra fields and load the formOptions.metadata if necessary.  Then continue on with the transaction
    func displayExtraFieldsIfNecessaryAndCompleteByTransactingWithDriver(driverClass: AcceptOnUIMachinePaymentDriver.Type) {
        self.state = .WaitingForTransaction
        
        //Executing this block would begin the driver transaction, but we want to check
        //to see if we need to show any extra fields first
        let startDriverTransaction = {
            self.activeDriver = driverClass.init(formOptions: self.options!)
            self.activeDriver.delegate = self
            self.activeDriver.beginTransaction()
        }
        
        
        //if userInfo was provided which holds things like 'should we show address'
        if let userInfo = self.userInfo {
            //Append any extra metadata
            if let extraMetaData = userInfo.extraMetadata {
                self.options.metadata = extraMetaData
            }
            
            //Determine if we should show the extra fields form by looking at the provided userInfo
            //Credit-card transactions don't require credit-card fields
            if (userInfo.requestsAndRequiresBillingAddress || userInfo.requestsAndRequiresShippingAddress) != true {
                startDriverTransaction()
                return
            }
    
            //Call up to retrieve any more metadata
            self.delegate?.acceptOnUIMachineDidRequestAdditionalUserInfo(userInfo, completion: { wasCancelled, extraFieldInfo in
                if wasCancelled {
                    self.state = .PaymentForm
                    self.delegate?.acceptOnUIMachinePaymentDidAbortPaymentMethodWithName?(driverClass.name)
                } else {
                    if let extraFieldInfo = extraFieldInfo {
                        for (k, v) in extraFieldInfo.toDictionary() {
                            self.options.metadata[k] = v
                        }
                    }
                    //Start rest of driver transaction
                    startDriverTransaction()
                }
            })
        } else {
            //No requirements or additional information provided.  Show no fields, start the driver transaction now
            startDriverTransaction()
        }
    }
}
