@objc public protocol AcceptOnUIMachineDelegate {
    optional func acceptOnUIMachineDidFailBegin(error: NSError)
    optional func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions)
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
    
    //This is typically the vc that created us
    public weak var delegate: AcceptOnUIMachineDelegate?

    /* ######################################################################################### */
    /* Stage II Initializers                                                                     */
    /* ######################################################################################### */
    //Signal from controller that we are ready to fetch data on the form configuration
    //and signal to the controller the didLoadFormWithConfig event for the given transaction
    //request
    var didBegin: Bool = false                          //Ensure that beginForItemWithDescription is only called once (Stage II Initializer)
    var tokenObject: AcceptOnAPITransactionToken? //Transaction token that was created during beginForItemWithDescription for the given parameters
    var amountInCents: Int?                             //Amount in cents of this transaction
    var itemDescription: String?                        //Description of this transaction
    var paymentMethods: AcceptOnAPIPaymentMethodsInfo?  //Retrieved by the AcceptOnAPI containing the form configuration (payment types accepted)
    var didFinishBegin: Bool = false                    //When the information is loaded and the form is ready to be displayed, etc.
    public func beginForItemWithDescription(description: String, forAmountInCents amountInCents: Int) {
        //Prevent race-conditions on didBegin check
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            //Can only be called at the start once.  It's a stage II initializer
            if (self?.didBegin != false) {
                self?.delegate?.acceptOnUIMachineDidFailBegin?(AcceptOnUIMachineError.errorWithCode(.DeveloperError, failureReason: "You already called beginForItemWithDescription; this should have been called once at the start.  You will have to make a new AcceptOnUIMachine for a new form"))
                return
            }
            self?.didBegin = true
            
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
                    self?.didFinishBegin = true
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
}