import Foundation
//List of API keys that have different services enabled with them

enum AcceptOnKeyProperty {
    case PaypalRest
    case Stripe
    case PublicKey
}

struct AcceptOnAPIKeyInfo {
    var key: String
    
    var properties: [AcceptOnKeyProperty]
    
    //Extra information, usually un-necessary but used for the specs
    var paypalRestClientSecret: String?
}

let keys = [
    AcceptOnAPIKeyInfo(key: "pkey_24b6fa78e2bf234d", properties: [.PaypalRest, .Stripe, .PublicKey], paypalRestClientSecret: nil
]

//Get a key with a set of properties
func apiKeyWithProperties(properties: [AcceptOnKeyProperty], withoutProperties: [AcceptOnKeyProperty]) -> String {
    //Must contain all mentioned properties
    var filteredKeys = keys.filter { keyInfo in
        for p in properties {
            if keyInfo.properties.indexOf(p) == nil { return false }
        }
        return true
    }

    //Must *not* contain all negatively mentioned properties
    filteredKeys = filteredKeys.filter { keyInfo in
        for p in withoutProperties {
            if keyInfo.properties.indexOf(p) != nil { return false }
        }
        return true
    }
    
    let resultKey = filteredKeys.first
    
    if resultKey == nil {
        NSException(name: "apiKeyWithProperties", reason: "Couldn't find an API key that had the properties of \(properties) without the properties of \(withoutProperties)", userInfo: nil).raise()
    }
    
    return resultKey!.key
}
