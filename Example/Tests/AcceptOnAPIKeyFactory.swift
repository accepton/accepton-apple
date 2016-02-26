import accepton

enum AcceptOnAPIKeyFactoryProperty {
    case PublicKey
    
    case Sandbox
    case Production
    
    case PaypalRest
    case Stripe
    
    case ApplePay
}

protocol AcceptOnAPIKeyFactoryResultProtocol {
    var key: String! { get set }
    var appleMerchantIdentifier: String? { get set }
    
    init(res: AcceptOnAPIKeyFactoryResultProtocol)
    init()
}

extension AcceptOnAPIKeyFactoryResultProtocol {
    init(res: AcceptOnAPIKeyFactoryResultProtocol) {
        self.init()
        self.key = res.key
        self.appleMerchantIdentifier = res.appleMerchantIdentifier
    }
}

struct AcceptOnAPIKeyFactoryResult {
    var key: String!
    var appleMerchantIdentifier: String?
    
    init(key: String, appleMerchantIdentifier: String?) {
        self.key = key
        self.appleMerchantIdentifier = appleMerchantIdentifier
    }
    
    init() {
    }
}

class AcceptOnAPIKeyFactory: Factory<AcceptOnAPIKeyFactoryResult, AcceptOnAPIKeyFactoryProperty> {
    required init() {
        super.init()
        
        context(.Stripe) {
            self.product {
                return AcceptOnAPIKeyFactoryResult(key: "pkey_89f2cc7f2c423553", appleMerchantIdentifier: nil) as! AcceptOnAPIKeyFactoryResult
            }
            
            self.product(.PaypalRest, .PublicKey, .ApplePay) {
                return AcceptOnAPIKeyFactoryResult(key: "pkey_24b6fa78e2bf234d", appleMerchantIdentifier: "merchant.com.accepton")
            }
        }
    }
}