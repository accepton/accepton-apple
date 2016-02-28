import Nimble

//Useful for mocking delegates by keeping track of incomming calls
protocol Spy: class {
    var callLog: [(name: String, args: [String:AnyObject])] { get set }
    
    var callLogNames: [String] { get }
    func logCall(name: String, withArgs args: [String:AnyObject])
}

extension Spy {
    func logCall(name: String, withArgs args: [String:AnyObject]) {
        callLog.append(name: name, args: args)
    }
    
    var callLogNames: [String] {
        return callLog.map { $0.name }
    }
}

struct SpyCallLogSlice {
    let callLog: [(name: String, args: [String:AnyObject])]
    
    var count: Int { return callLog.count }
}

func haveInvoked(selector: String) -> NonNilMatcherFunc<Spy> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "have invoked \(selector)."
        
        if let spy = try actualExpression.evaluate() {
            //Match the call, check if it existed in the log
            let possibleResult = spy.callLog.filter { $0.name == selector }.first
            if possibleResult != nil {
                return true
            } else {
                failureMessage.postfixMessage += " The \(selector) did not exist in the log which contained: \(spy.callLogNames)"
                return false
            }
        } else {
            return false
        }
    }
}

func haveInvoked(selector: String, withMatchingArgExpression argExp: (args: [String:AnyObject])->(Bool)) -> NonNilMatcherFunc<Spy> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "have invoked \(selector)."
        
        if let spy = try actualExpression.evaluate() {
            //Match the call, check if it existed in the log
            let possibleResult = spy.callLog.filter { $0.name == selector }.first
            if let result = possibleResult {
                if argExp(args: result.args) {
                    return true
                } else {
                    failureMessage.postfixMessage += " The \(selector) *did* exist in log! (but) the argument expression failed to match \(result.args) for \(result.name)"
                    return false
                }
            } else {
                failureMessage.postfixMessage += " The \(selector) did not exist in the log which contained: \(spy.callLogNames)"
                return false
            }
        } else {
            return false
        }
    }
}

//Matcher helpers for Spy
//func haveTheCall(card: AcceptOnAPICreditCardParams) -> NonNilMatcherFunc<[String:AnyObject]> {
//    return NonNilMatcherFunc { actualExpression, failureMessage in
//        failureMessage.postfixMessage = "represent complaint 'card' field for AcceptOn /v1/Charges endpoint for given raw credit-card parameters."
//        
//        if let cardInfo = try actualExpression.evaluate() {
//            guard let number = cardInfo["number"] as? String where number == card.number else {
//                failureMessage.postfixMessage += " The cardInfo field 'number' was non-existant"
//                return false
//            }
//            
//            guard let expMonth = cardInfo["exp_month"] as? String where expMonth == card.expMonth else {
//                failureMessage.postfixMessage += " The cardInfo field 'expMonth' was non-existant"
//                return false
//            }
//            
//            guard let expYear = cardInfo["exp_year"] as? String where expYear == card.expYear else {
//                failureMessage.postfixMessage += " The cardInfo field 'expYear' was non-existant"
//                return false
//            }
//            
//            guard let security = cardInfo["security_code"] as? String where security == card.cvc else {
//                failureMessage.postfixMessage += " The cardInfo field 'security_code' was non-existant"
//                return false
//            }
//            
//            return true
//        } else { return false }
//    }
//}