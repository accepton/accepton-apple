@objc public protocol AcceptOnUIMachineDelegate {
    //Start-up
    optional func acceptOnUIMachineDidFailBegin(error: NSError)
    optional func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions)
    
    //Credit-card form
    optional func acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String)
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
    case Initialized    //begin has not been called
    case BeginWasCalled //In the middle of the begin
    case PaymentForm    //begin succeeded
}

public class AcceptOnUIMachine {
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
            if (_currentFocusedCreditCardFieldName != nil) {
                validateCreditCardFieldWithName(_currentFocusedCreditCardFieldName)
            }
            
            _currentFocusedCreditCardFieldName = newFieldName
        }
        
        get {
            return _currentFocusedCreditCardFieldName
        }
    }
    
    //Values of various fields
    var emailFieldValue: String = ""
    
    //Called every time a credit-card field needs validation (loses focus)
    func validateCreditCardFieldWithName(name: String?) {
        if (name == "email") {
            delegate?.acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName?("email", withMessage: "Invalid email test")
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
}