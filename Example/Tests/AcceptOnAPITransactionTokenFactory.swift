import accepton

enum AcceptOnAPITransactionTokenFactoryProperty: Equatable {
    case NonBogus
    case Bogus
    
    case Item(tid: String, costInUSDCents: Int?, desc: String)
    
    var itemValue: (tid: String, costInUSDCents: Int?, desc: String)! {
        switch self {
        case let .Item(tid, costInUSDCents, desc):
            return (tid: tid, costInUSDCents: costInUSDCents, desc: desc)
        default:
            return nil
        }
    }
}

func ==(lhs: AcceptOnAPITransactionTokenFactoryProperty, rhs: AcceptOnAPITransactionTokenFactoryProperty) -> Bool {
    switch (lhs, rhs) {
    case (.Item(_, let cl, _), .Item(_, let cr, _)):
        //If both are not nil, then during the search, use the cost to match exactly (good for finding $0.00)
        if cl != nil && cr != nil { return cl == cr }
        return true
    case (.Bogus, .Bogus):
        return true
    case (.NonBogus, .NonBogus):
        return true
    default:
        return false
    }
}

class AcceptOnAPITransactionTokenFactory: Factory<AcceptOnAPITransactionToken, AcceptOnAPITransactionTokenFactoryProperty> {
    required init() {
        super.init()
        
        context(.Bogus) {
            var tid: String { return "bogus-transaction-id-xxx" }
            
            func addHipsterDressWithCostInUSDCents(cost: Int) {
                var item: AcceptOnAPITransactionTokenFactoryProperty { return .Item(tid: tid, costInUSDCents: cost, desc: "Hipster Dress") }
                
                self.product(item) {
                    return AcceptOnAPITransactionToken.parseTokenRes([
                        "description": item.itemValue.desc,
                        "id": item.itemValue.tid,
                        "amount": item.itemValue.costInUSDCents!
                    ])!
                }
            }
            
            addHipsterDressWithCostInUSDCents(0)
            addHipsterDressWithCostInUSDCents(100)
            addHipsterDressWithCostInUSDCents(1000)
            addHipsterDressWithCostInUSDCents(1333)
        }
    }
}