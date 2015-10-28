import Alamofire

//See /docs/AcceptOnAPI.md for details of most classes and structs in this file

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

public enum AcceptOnAPIPaymentTypes {
    case CreditCard
    case Stripe
    case Paypal
    case Applepay
}

//Returned for the payment methods requests.  Describes what payments are available.
public struct AcceptOnAPIPaymentMethodsInfo {
    public var supportsCreditCard: Bool = false
    public var supportsStripe: Bool = false
    public var supportsPaypal: Bool = false
    public var supportsApplePay: Bool = true
    
    public var processorInfo: [String:AnyObject]?
    
    //Tries to take the /v1/form/configure endpoint JSON info and convert it to
    //a info object. Returns nil if failed to parse correctly.
    static public func parseConfig(config: [String: AnyObject]) -> AcceptOnAPIPaymentMethodsInfo? {
        var info: AcceptOnAPIPaymentMethodsInfo = AcceptOnAPIPaymentMethodsInfo()
        
        if let paymentMethods = config["payment_methods"] as? [String] {
            if paymentMethods.contains("paypal") {
                info.supportsPaypal = true
            }
            
            if paymentMethods.contains("credit-card") {
                info.supportsCreditCard = true
            }
        } else {
            return nil
        }
        
        if let processorInfo = config["processor_information"] as? [String:AnyObject] {
            info.processorInfo = processorInfo
        } else {
            return nil
        }
        
        return info
    }
    
    public init() {}
}

//Helper struct that converts the original dictionary returned from the transaction creation into a
//swift object
public struct AcceptOnAPITransactionToken {
    
    public var id: String!
    public var amountInCents: Int!
    public var desc: String!
    
    static public func parseTokenRes(tokenRes: [String: AnyObject]) -> AcceptOnAPITransactionToken? {
        //Create the object we are going to return
        var t: AcceptOnAPITransactionToken = AcceptOnAPITransactionToken()
        
        //Get the various fields specified in http://developers.accepton.com/#transaction-tokens
        if let id = tokenRes["id"] as? String {
            t.id = id
        } else { return nil }
        
        if let amount = tokenRes["amount"] as? Int {
            t.amountInCents = amount
        } else { return nil }
        
        if let description = tokenRes["description"] as? String {
            t.desc = description
        } else { return nil }
    
        return t
    }
    
    public init() {}
}

//Helper struct for the charge methods (which have a lot of parameters and variations of parameters)
public struct AcceptOnAPIChargeInfo {
    var cardToken: String?
    var email: String?
    
    public init(cardToken: String, email: String?) {
        self.cardToken = cardToken
        self.email = email
    }
    
    //Places all necessary info into an already created params struct (usually this would
    //have the session key already in it, so we place all the requisite fields for the
    //charge request)
    public func mergeIntoParams(inout dict: [String:AnyObject]) {
        if let cardToken = cardToken {
            dict["card_token"] = cardToken
            dict["email"] = email ?? ""
        }
    }
}

//Actual API class
public class AcceptOnAPI {
    /* ######################################################################################### */
    /* Endpoint Communication Helpers                                                            */
    /* ######################################################################################### */
    //The endpoint URL we are communicating with for all API calls
    static let endpointUrl = "https://staging-checkout.accepton.com"
    
    //Makes an AcceptOnAPI network request to the `path`, e.g. if you passed in `/v1/tokens` for path
    //then you would make a request to something like `https://staging-checkout.accepton.com/v1/tokens`
    //depending on the value of endpoint_url above
    static public func requestWithMethod(method: Alamofire.Method, path: String, params: [String:AnyObject]?, completion: (res: [String:AnyObject]?, error:NSError?) -> ()) {
        //Get the full network request path, e.g. https://staging-checkout.accepton.com + /v1/tokens
        let fullPath = "\(endpointUrl)/\(path)"
        
        //Make a request
        Alamofire.request(method, fullPath, parameters: params).responseJSON { response in
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
    
    /* ######################################################################################### */
    /* Constructors & Members                                                                    */
    /* ######################################################################################### */
    public var accessToken: String!
    public init(publicKey: String) {
        accessToken = publicKey
    }
    
    public init(secretKey: String) {
        accessToken = secretKey
    }

    /* ######################################################################################### */
    /* API Request Functions                                                                     */
    /* ######################################################################################### */
    public func createTransactionTokenWithDescription(description: String, forAmountInCents amount: Int, completion: (token: AcceptOnAPITransactionToken?, error: NSError?) -> ()) {
        let params = ["access_token":self.accessToken, "amount": String(amount), "description": description]
        
        AcceptOnAPI.requestWithMethod(.POST, path:"/v1/tokens", params: params, completion: { res, err in
            if (err != nil) {
                completion(token: nil, error: err)
            } else {
                //Make sure our response is a valid Transaction Token Object by checking for an id
                if let tokenObject = AcceptOnAPITransactionToken.parseTokenRes(res!) {
                    completion(token: tokenObject, error: nil)
                } else {
                    completion(token: nil, error: AcceptOnAPIError.errorWithCode(.MalformedOrNonExistantData, failureReason: "Tried to create a transaction token for item with description: '\(description)' for amountInCents: '\(amount)', but the returned JSON did not have an id field.  The JSON was expected to return a 'Transaction Token Object' as described in the AcceptOn API documentation at http://developers.accepton.com/#transaction-tokens but this had no such id field. We did get a 2XX response and the JSON was well formed, the JSON just didn't contain the expected fields)"))
                }
            }
        })
    }
    
    public func getAvailablePaymentMethodsForTransactionWithId(tid: String, completion: (paymentMethods: AcceptOnAPIPaymentMethodsInfo?, error: NSError?) -> ()) {
        let params = ["access_token":self.accessToken, "token_id": tid]
        
        AcceptOnAPI.requestWithMethod(.GET, path:"/v1/form/configure", params: params, completion: { res, err in
            if (err != nil) {
                completion(paymentMethods: nil, error: err)
            } else {
                if let config = res?["config"] as? [String:AnyObject] {
                    if let info = AcceptOnAPIPaymentMethodsInfo.parseConfig(config) {
                        completion(paymentMethods: info, error: nil)
                    } else {
                        completion(paymentMethods: nil, error: AcceptOnAPIError.errorWithCode(.MalformedOrNonExistantData, failureReason: "Couldn't parse the paymentMethods configuration correctly, but did receive the configuration response from AcceptOn (And it was valid JSON).  Something may have changed in the schema of the dictionary returned by /v1/form/configure."))
                    }
                    return
                }
                
                completion(paymentMethods: nil, error: AcceptOnAPIError.errorWithCode(.MalformedOrNonExistantData, failureReason: "AcceptOn's API returned payment information, but it could not be processed. This may be a JSON formatting issue, no data was returned, or a schema change for the /v1/form/configure response for payment information"))
            }
        })
    }
    
    //WIP: Need to get stripe or paypal to work before I can test this
    public func chargeWithTransactionId(tid: String, andChargeinfo chargeInfo: AcceptOnAPIChargeInfo, completion: (chargeRes: [String: AnyObject]?, error: NSError?) -> ()) {
        //Place the requisite authentication and token parameters in, and then
        //merge the charge information setup in the AcceptOnAPIChargeInfo struct.
        //The merge contains things like the 'card_token' or in some cases the
        //actual credit card numbers.
        var params = ["access_token":self.accessToken, "token": tid] as [String:AnyObject]
        chargeInfo.mergeIntoParams(&params)
        
        AcceptOnAPI.requestWithMethod(.GET, path:"/v1/charges", params: params, completion: { res, err in
            if (err != nil) {
                completion(chargeRes: nil, error: err)
            } else {
                completion(chargeRes: res, error: nil)
            }
        })
    }
    
    //WIP: Need to be able to make charges to test this
    public func refundChargeWithTransactionId(tid: String, andChargeId chargeId: String, forAmountInCents amountInCents: Int, completion: (refundRes: [String: AnyObject]?, error: NSError?) -> ()) {
        let params = ["access_token":self.accessToken, "token": tid, "charge_id": chargeId, "amount": amountInCents] as [String:AnyObject]
        
        AcceptOnAPI.requestWithMethod(.GET, path:"/v1/refunds", params: params, completion: { res, err in
            if (err != nil) {
                completion(refundRes: nil, error: err)
            } else {
                completion(refundRes: res, error: nil)
            }
        })
    }
}
