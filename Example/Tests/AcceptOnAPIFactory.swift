import accepton

struct AcceptOnAPIFactoryResult: AcceptOnAPIKeyFactoryResultProtocol {
    var api: AcceptOnAPI!
    var key: String!
    var appleMerchantIdentifier: String?
    
    init() {}
    init(res: AcceptOnAPIKeyFactoryResultProtocol, api: AcceptOnAPI) {
        self.init(res: res)
    }
}

class AcceptOnAPIFactory: Factory<AcceptOnAPIFactoryResult, AcceptOnAPIKeyFactoryProperty> {
    required init() {
        super.init()
        
        AcceptOnAPIKeyFactory.query.eachWithProperties { res, desc, properties in
            self.product(properties: properties) {
                let api = AcceptOnAPI(publicKey: res.key, isProduction: true)
                let result = AcceptOnAPIFactoryResult(res: res as! AcceptOnAPIKeyFactoryResultProtocol, api: api)
                
                return result
            }
        }
    }
}