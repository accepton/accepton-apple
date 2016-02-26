import accepton

struct AcceptOnAPIFactoryResult: AcceptOnAPIKeyFactoryResultProtocol {
    var api: AcceptOnAPI!
    var key: String!
    var appleMerchantIdentifier: String?
    
    init() {}
    init(res: AcceptOnAPIKeyFactoryResultProtocol, api: AcceptOnAPI) {
        self.init(res: res)
        self.api = api
    }
}

class AcceptOnAPIFactory: Factory<AcceptOnAPIFactoryResult, AcceptOnAPIKeyFactoryProperty> {
    required init() {
        super.init()
        
        AcceptOnAPIKeyFactory.eachWithProperties { res, desc, properties in
            self.product(properties: properties) {
                let api = AcceptOnAPI(publicKey: res.key, isProduction: properties.contains(.Production))
                let result = AcceptOnAPIFactoryResult(res: res, api: api)
                
                return result
            }
        }
    }
}