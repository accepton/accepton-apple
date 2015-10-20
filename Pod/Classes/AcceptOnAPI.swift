import Alamofire

//Contains error codes for AcceptOnAPI & convenience methods
public struct AcceptOnAPIError {
    public static let domain = "com.accepton.api.error"
    
    public enum Code: Int {
        case BadRequest = -4400
        case Unauthorized = -4501
        case NotFound = -4404
        case InternalServerError = -4500
        case ServiceUnavailable = -4503
        case NetworkIssues = -4444
    }
    
    //Creates an NSError given the error code and failure reason
    public static func errorWithCode(code: Code, failureReason: String) -> NSError {
        let info = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: domain, code: code.rawValue, userInfo: info)
    }
}

public class AcceptOnAPI {
    public func holahOnResponse() {
        //Token Stub
        Alamofire.request(.POST, "https://staging-checkout.accepton.com/v1/tokens", parameters: ["access_token":"pkey_24b6fa78e2bf234d", "amount":"1000", "description":"Hipster T-Shirt"]).responseJSON { response in
            
            if let JSON = response.result.value {
                let id = JSON["id"] as! String
            }
        }
    }
    
    //The endpoint URL we are communicating with for all API calls
    static let endpoint_url = "https://staging-checkout.accepton.com"

    //Returns the resource url, e.g. if you pass in /v1/tokens it might yield
    //https://staging-checkout.accepton.com/v1/tokens depending on the value
    //of endpoint_url
    static public func path(path: String) -> String {
        return "\(endpoint_url)/\(path)"
    }
    
    public var accessToken: String!
    public init(publicKey: String) {
        accessToken = publicKey
    }
    
    public init(secretKey: String) {
        accessToken = secretKey
    }
    
    public func getAvailablePaymentMethodsforTransactionWithId(tid: String, completion: (paymentMethods: String, error: NSError?) -> ()) {
    }
    
    public func createTransactionTokenWithDescription(description: String, forAmountInCents amount: Int, completion: (tokenRes: [String:AnyObject]?, error: NSError?) -> ()) {
        let params = ["access_token":self.accessToken, "amount": String(amount), "description": description]
        
        Alamofire.request(.POST, AcceptOnAPI.path("/v1/tokens"), parameters: params).responseJSON { response in
            switch response.result {
            case .Success:
                if let JSON = response.result.value as? [String:AnyObject] {
                    completion(tokenRes: JSON, error: nil)
                } else {
                    
                }
            case .Failure(let error):
                print("fail \(error)")
            }
        }
    }
}