import Alamofire

//Contains error codes for AcceptOnAPI & convenience methods
public struct AcceptOnAPIError {
    public static let domain = "com.accepton.api.error"
    
    public enum Code: Int {
        case BadRequest = -4400
        case Unauthorized = -4401
        case NotFound = -4404
        case InternalServerError = -4500
        case ServiceUnavailable = -4503
        case UnknownCode = -4111
        case NetworkIssues = -4444
        case MalformedOrNonExistantData = -4445
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
    static let endpointUrl = "https://staging-checkout.accepton.com"
    
    //Makes an AcceptOnAPI network request to the `path`, e.g. if you passed in `/v1/tokens` for path
    //then you would make a request to something like `https://staging-checkout.accepton.com/v1/tokens`
    //depending on the value of endpoint_url above
    static public func requestWithPath(path: String, params: [String:AnyObject]?, completion: (res: [String:AnyObject]?, error:NSError?) -> ()) {
        //Get the full network request path, e.g. https://staging-checkout.accepton.com + /v1/tokens
        let fullPath = "\(endpointUrl)/\(path)"
        
        //Make a request
        Alamofire.request(.POST, fullPath, parameters: params).responseJSON { response in
            switch response.result {
            case .Success:
                //If the status code isn't a 200, return an error
                if let statusCode = response.response?.statusCode {
                    switch statusCode {
                    case 200...299:
                        //Good HTTP response
                        break
                    case 400:
                        completion(res: nil, error:AcceptOnAPIError.errorWithCode(.BadRequest, failureReason: "AcceptOn's API returned Bad Request 400"))
                        return
                    case 401:
                        completion(res: nil, error:AcceptOnAPIError.errorWithCode(.Unauthorized, failureReason: "AcceptOn's API returned Unauthorized 401"))
                        return
                    case 404:
                        completion(res: nil, error:AcceptOnAPIError.errorWithCode(.NotFound, failureReason: "AcceptOn's API returned Not Found 404"))
                        return
                    case 500:
                        completion(res: nil, error:AcceptOnAPIError.errorWithCode(.InternalServerError, failureReason: "AcceptOn's API returned Internal Server Error 500"))
                        return
                    case 503:
                        completion(res: nil, error:AcceptOnAPIError.errorWithCode(.ServiceUnavailable, failureReason: "AcceptOn's API returned Service Unavailable 503"))
                        return
                    default:
                        completion(res: nil, error: AcceptOnAPIError.errorWithCode(.UnknownCode, failureReason: "AcceptOn's API returned an unknown code: \(statusCode)"))
                    }
                }
                
                if let json = response.result.value as? [String:AnyObject] {
                    completion(res: json, error: nil)
                } else {
                    completion(res: nil, error: AcceptOnAPIError.errorWithCode(.MalformedOrNonExistantData, failureReason: "AcceptOn's API returned data that could not be converted into JSON. It may be blank or malformed JSON."))
                }
            case .Failure(let error):
                completion(res: nil, error: AcceptOnAPIError.errorWithCode(.NetworkIssues, failureReason: "Could not connect to the network \(error)."))
            }
        }
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
        
        AcceptOnAPI.requestWithPath("/v1/tokens", params: params, completion: { res, err in
            if (err != nil) {
                completion(tokenRes: nil, error: err)
            } else {
                completion(tokenRes: res, error: nil)
            }
        })
    }
}