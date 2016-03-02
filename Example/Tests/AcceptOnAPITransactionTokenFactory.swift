import accepton

enum AcceptOnAPITransactionTokenFactoryProperty: Equatable {
    case Sandbox
    case Bogus
    
    case Item(costInUSDCents: Int?, desc: String)
    
    var itemValue: (costInUSDCents: Int?, desc: String)! {
        switch self {
        case let .Item(costInUSDCents, desc):
            return (costInUSDCents: costInUSDCents, desc: desc)
        default:
            return nil
        }
    }
}

func ==(lhs: AcceptOnAPITransactionTokenFactoryProperty, rhs: AcceptOnAPITransactionTokenFactoryProperty) -> Bool {
    switch (lhs, rhs) {
    case (.Item(let cl, _), .Item(let cr, _)):
        //If both are not nil, then during the search, use the cost to match exactly (good for finding $0.00)
        if cl != nil && cr != nil { return cl == cr }
        return true
    case (.Bogus, .Bogus):
        return true
    case (.Sandbox, .Sandbox):
        return true
    default:
        return false
    }
}

struct AcceptOnAPITransactionTokenFactoryResult {
    let token: AcceptOnAPITransactionToken
    let api: AcceptOnAPI?
}

class AcceptOnAPITransactionTokenFactory: Factory<AcceptOnAPITransactionTokenFactoryResult, AcceptOnAPITransactionTokenFactoryProperty> {
    required init() {
        super.init()
        
        context(.Bogus) {
            var tid: String { return "bogus-transaction-id-xxx" }
            1
            func addHipsterDressWithCostInUSDCents(cost: Int) {
                var item: AcceptOnAPITransactionTokenFactoryProperty { return .Item(costInUSDCents: cost, desc: "Hipster Dress") }
                
                self.product(item) {
                    return AcceptOnAPITransactionTokenFactoryResult(token: AcceptOnAPITransactionToken.parseTokenRes([
                        "description": item.itemValue.desc,
                        "id": tid,
                        "amount": item.itemValue.costInUSDCents!
                        ])!, api: nil)
                }
            }
            
            addHipsterDressWithCostInUSDCents(0)
            addHipsterDressWithCostInUSDCents(100)
            addHipsterDressWithCostInUSDCents(1000)
            addHipsterDressWithCostInUSDCents(1333)
        }
        
        context(.Sandbox) {
            AcceptOnAPIFactory.withAtleast(.Sandbox).each { api, apiFactoryRes in
                self.context(withExtraDescs: ["apiFactoryRes": apiFactoryRes]) {
                    let products = [
                        (description: "Hipster Dress", amountInCents: 0),
                        (description: "Hipster Dress", amountInCents: 100),
                        (description: "Hipster Dress", amountInCents: 1000),
                        (description: "Hipster Dress", amountInCents: 1333),
                    ]
                    
                    for p in products {
                        let item = AcceptOnAPITransactionTokenFactoryProperty.Item(costInUSDCents: p.amountInCents, desc: p.description)
                        self.product(properties: [item], withExtraDesc: [:]) {
                            puts("Invoked product...")
                            let sem = dispatch_semaphore_create(0)
                            var tokenRes: AcceptOnAPITransactionToken!
                            
                            api.api.createTransactionTokenWithDescription(p.description, forAmountInCents: p.amountInCents, completion: { (token, error) -> () in
                                if let token = token {
                                    tokenRes = token
                                } else {
                                    puts("Failed to create token for \(p)")
                                    assertionFailure()
                                }
                                
                                dispatch_semaphore_signal(sem)
                                puts("product made")
                            })
                            
                            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
                            
                            return AcceptOnAPITransactionTokenFactoryResult(token: tokenRes, api: api.api)
                        }
                    }
                }
            }
        }
    }
}