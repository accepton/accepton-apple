import PassKit

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

//Returned for the payment methods requests.  Describes what payments are available.
public class AcceptOnAPIPaymentMethodsInfo {
    public var supportsStripe: Bool {
        return stripePublishableKey != nil
    }
    
    //TODO: Check against accepton API
    public var supportsBraintree: Bool {
        return braintreeNonce != nil
    }
    
    //TODO: Retrieve from accepton API
    var braintreeNonce: String? {
        return nil
    }
    
    public var paypalRestClientId: String? {
        puts("\(processorInfo)")
        guard let paypalInfo = processorInfo?["paypal_rest"] as? [String:AnyObject] else {
            return nil
        }
        
        guard let paypalClientId = paypalInfo["client_id"] as? String else {
            return nil
        }
        
        return paypalClientId
    }
    
    public var supportsPaypal: Bool {
        return paypalRestClientId != nil
    }
    
    public var supportsApplePay: Bool {
        return true
    }
    
    //Stripe-id
    public var stripePublishableKey: String? {
        guard let stripeInfo = creditCardProcessorInfo?["stripe"] as? [String:AnyObject] else {
            return nil
        }
        
        guard let publishKey = stripeInfo["publishable_key"] as? String else {
            return nil
        }
        
        return publishKey
    }
    
    //List of methods acceptod, e.g. paypal, credit_card
    public var paymentMethods: [String]? {
        return config["payment_methods"] as? [String]
    }
    
    //Can process credit-cards
    public var supportsCreditCard: Bool {
        return paymentMethods?.contains("credit-card") ?? false
    }
    
    //Processor specific information
    public var processorInfo: [String:AnyObject]? {
        return config["processor_information"] as? [String:AnyObject]
    }
    
    //Credit-card specific processor info
    public var creditCardProcessorInfo: [String:AnyObject]? {
        return processorInfo?["credit-card"] as? [String:AnyObject]
    }
    
    //Loaded directly from server response on form configuration
    var config: [String:AnyObject]!
    
    //For testing purposes
    func addMocksToConfig() {
        guard var processorInfo = config["processor_information"] as? [String:AnyObject]  else {
            return
        }
        
        processorInfo["paypal_rest"] = [
            "client_id": "Ab70mPDg9HPDJRGavtsg-OmhoLH2xSHbCiw6G9e9d_wmwVBkbKWEybaZxyQMX3K3x6h89oFa9HWhrH31"
        ]
        
        //CoW
        config["processor_information"] = processorInfo
    }
    
    public init() {}
    
    static public func parseConfig(config: [String: AnyObject]) -> AcceptOnAPIPaymentMethodsInfo? {
        var info = AcceptOnAPIPaymentMethodsInfo()
        info.config = config
        info.addMocksToConfig()
        
        //Config must contain payment methods or processor information
        if info.paymentMethods == nil { return nil }
        if info.processorInfo == nil { return nil }
        
        return info
    }
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
    //An array of tokens to charge
    var cardTokens: [String:AnyObject]?
    
    //'Extra' Metadata the user may pass in
    var metadata: [String:AnyObject]?
    
    var email: String?
    
    public init(cardTokens: [String:AnyObject], email: String?=nil, metadata: [String:AnyObject]?=nil) {
        self.cardTokens = cardTokens
        self.metadata = metadata
        self.email = email
    }
    
    //Places all necessary info into an already created params struct (usually this would
    //have the session key already in it, so we place all the requisite fields for the
    //charge request)
    public func mergeIntoParams(inout dict: [String:AnyObject]) {
        if let cardTokens = cardTokens {
            dict["card_tokens"] = cardTokens
            
            dict["email"] = email ?? ""
            
            dict["metadata"] = metadata ?? [:]
        }
    }
}

//Used for auto-completion results
public struct AcceptOnAPIAddress {
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    public var line1: String?
    public var line2: String?
    public var country: String?
    public var city: String?
    public var region: String?
    public var postalCode: String?
    
    public init(line1: String?, country: String?, region: String?, city: String?, postalCode: String?) {
        self.line1 = line1
        self.country = country
        self.region = region
        self.city = city
        self.postalCode = postalCode
    }
    
    public init(line1: String?, line2: String?, country: String?, region: String?, city: String?, postalCode: String?) {
        self.line1 = line1
        self.line2 = line2
        self.country = country
        self.region = region
        self.city = city
        self.postalCode = postalCode
    }
    
    //The address refers to one location.  Used to verify that address returned from place id
    //dosen't refer to a general region
    var isFullyQualified: Bool {
        let c = [line1, country, city, region, postalCode]
        for e in c {
            if e == nil { return false }
        }
        return true
    }
    
    func toDictionary() -> [String:AnyObject] {
        var out: [String:AnyObject] = [:]
        
        if let line1 = line1 {
            out["line1"] = line1
        }

        if let line2 = line2 {
            out["line2"] = line2 
        } 

        if let country = country {
            out["country"] = country 
        } 

        if let city = city {
            out["city"] = city 
        } 

        if let region = region {
            out["region"] = region 
        } 

        if let postalCode = postalCode {
            out["postalCode"] = postalCode 
        } 

        
        return out
    }
}

//Actual API class
@objc public class AcceptOnAPI: NSObject {
    /* ######################################################################################### */
    /* Endpoint Communication Helpers                                                            */
    /* ######################################################################################### */
    //The endpoint URL we are communicating with for all API calls
    let stagingEndpointURL = "https://staging-checkout.accepton.com"
    let productionEndpointURL = "https://checkout.accepton.com"
    
    let isProduction: Bool
    var endpointUrl: String {
        get {
            return isProduction ? self.productionEndpointURL : self.stagingEndpointURL
        }
    }
    
    //Makes an AcceptOnAPI network request to the `path`, e.g. if you passed in `/v1/tokens` for path
    //then you would make a request to something like `https://staging-checkout.accepton.com/v1/tokens`
    //depending on the value of endpoint_url above
    public func requestWithMethod(method: Method, path: String, params: [String:AnyObject]?, completion: (res: [String:AnyObject]?, error:NSError?) -> ()) {
        //Get the full network request path, e.g. https://staging-checkout.accepton.com + /v1/tokens
        let fullPath = "\(endpointUrl)\(path)"
        
        //Make a request
        request(method, fullPath, parameters: params).responseJSON { response in
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
                puts("AcceptonAPI connection failed. \(error) Retrying...")
                let delay = Int64(1000) * Int64(NSEC_PER_MSEC)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue(), { [weak self] () -> Void in
                    self?.requestWithMethod(method, path: path, params: params, completion: completion)
                })
//                completion(res: nil, error: AcceptOnAPIError.errorWithCode(.NetworkIssues, failureReason: "Could not connect to the network \(error)."))
            }
        }
    }
    
    /* ######################################################################################### */
    /* Constructors & Members                                                                    */
    /* ######################################################################################### */
    public var accessToken: String!
    public init(publicKey: String, isProduction: Bool) {
        accessToken = publicKey
        self.isProduction = isProduction
    }
    
    public init(secretKey: String, isProduction: Bool) {
        accessToken = secretKey
        self.isProduction = isProduction
    }

    /* ######################################################################################### */
    /* API Request Functions                                                                     */
    /* ######################################################################################### */
    public func createTransactionTokenWithDescription(description: String, forAmountInCents amount: Int, completion: (token: AcceptOnAPITransactionToken?, error: NSError?) -> ()) {
        let params = ["access_token":self.accessToken, "amount": String(amount), "description": description]
        
        requestWithMethod(.POST, path:"/v1/tokens", params: params, completion: { res, err in
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
        
        requestWithMethod(.GET, path:"/v1/form/configure", params: params, completion: { res, err in
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
        
        requestWithMethod(.POST, path:"/v1/charges", params: params, completion: { res, err in
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
        
        requestWithMethod(.GET, path:"/v1/refunds", params: params, completion: { res, err in
            if (err != nil) {
                completion(refundRes: nil, error: err)
            } else {
                completion(refundRes: res, error: nil)
            }
        })
    }
    
    //-----------------------------------------------------------------------------------------------------
    //PayPal verification endpoint, the first card token should be the paypal payment token
    //-----------------------------------------------------------------------------------------------------
    public func verifyPaypalWithTransactionId(tid: String, andChargeInfo chargeInfo: AcceptOnAPIChargeInfo, completion: (chargeRes: [String: AnyObject]?, error: NSError?) -> ()) {
        //Place the requisite authentication and token parameters in, and then
        //merge the charge information setup in the AcceptOnAPIChargeInfo struct.
        //The merge contains things like the 'card_token' or in some cases the
        //actual credit card numbers.
        var params = ["access_token":self.accessToken, "token": tid] as [String:AnyObject]
        chargeInfo.mergeIntoParams(&params)
        
        requestWithMethod(.POST, path:"/v1/mobile/paypal/verify", params: params, completion: { res, err in
            if (err != nil) {
                completion(chargeRes: nil, error: err)
            } else {
                completion(chargeRes: res, error: nil)
            }
        })
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Relating to geo-location (for auto-completing addresses)
    //-----------------------------------------------------------------------------------------------------
    public func autoCompleteAddress(input: String, completion: (addressResults: [(description: String, placeId: String)]?, err: NSError?)->()) {
        //Make a request
        request(.GET, "http://localhost:5555/places/autocomplete", parameters: ["input":input]).responseJSON { response in
            switch response.result {
            case .Success:
                if let json = response.result.value as? [String:AnyObject] {
                    let results = json["results"] as! [[String:AnyObject]]
                    var options: [(description: String, placeId: String)] = []
                    for e in results {
                        let description = e["description"] as! String
                        let placeId = e["place_id"] as! String
                        options.append((description: description, placeId: placeId))
                    }
                    
                    completion(addressResults: options, err: nil)
                } else {
                }
            case .Failure(let error):
                puts("\(error)")
                break
            }
        }
    }
    
    public func convertPlaceIdToAddress(placeId: String, completion: (address: AcceptOnAPIAddress?, err: NSError?)->()) {
        //Make a request
        request(.GET, "http://localhost:5555/places/convert_place_id_to_address", parameters: ["place_id":placeId]).responseJSON { response in
            switch response.result {
            case .Success:
                if let json = response.result.value as? [String:AnyObject] {
                    let line1 = json["line_1"] as? String
                    let country = json["country"] as? String
                    let city = json["city"] as? String
                    let region = json["region"] as? String
                    let postalCode = json["postal_code"] as? String
                    
                    let address = AcceptOnAPIAddress(line1: line1, country: country, region: region, city: city, postalCode: postalCode)
                    completion(address: address, err: nil)
                } else {
                }
            case .Failure(let error):
                puts("\(error)")
                break
            }
        }
    }
}
