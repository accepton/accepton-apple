// https://github.com/Quick/Quick

import Quick
import Nimble
import accepton

class AcceptOnAPISpec: QuickSpec {
    override func spec() {
        describe("init") {
            it("can be created with a public or secret key") {
                let api = AcceptOnAPI.init(publicKey: "test")
                expect(api.accessToken) == "test"
                
                let api2 = AcceptOnAPI.init(secretKey: "test2")
                expect(api2.accessToken) == "test2"
            }
        }
        
        describe("createTransactionToken") {
            it("does fail with Unauthorized if a fake access token is given") {
                let api = AcceptOnAPI.init(publicKey: "no_such_token")
                var error: NSError? = nil
                api.createTransactionTokenWithDescription("No Such T-Shirt", forAmountInCents: 100, completion: { (tokenRes, _error) -> () in
                    error = _error
                })
                
                expect {
                    return error?.code
                }.toEventually(equal(AcceptOnAPIError.Code.Unauthorized.rawValue))
            }
            
            it("does retrieve a transaction token when a working access token is given") {
                let api = AcceptOnAPI.init(publicKey: "pkey_89f2cc7f2c423553")
                var tokenRes: [String: AnyObject]? = nil
                api.createTransactionTokenWithDescription("T-Shirt", forAmountInCents: 100, completion: { (_tokenRes, _error) -> () in
                    tokenRes = _tokenRes
                })
                
                //Should have returned a transaction token whose id starts with txn_
                expect {
                    return tokenRes?["id"] as? String
                }.toEventually(contain("txn_"))
                
                //Should have returned cents of the transaction (100 cents)
                expect {
                    return tokenRes?["amount"] as? Int
                }.toEventually(equal(100))
            }
        }
        
        describe("getAvailablePaymentMethods") {
            it("does get payment methods for a transaction") {
                var paymentMethods: AcceptOnAPIPaymentMethodsInfo? = nil
                
                //Create a transaction token
                let api = AcceptOnAPI.init(publicKey: "pkey_89f2cc7f2c423553")
                api.createTransactionTokenWithDescription("T-Shirt", forAmountInCents: 100, completion: { (tokenRes, _error) -> () in
                    //Grab the transaction token
                    let tid = tokenRes!["id"] as! String
                    
                    api.getAvailablePaymentMethodsForTransactionWithId(tid, completion: { (_paymentMethods, error) -> () in
                        paymentMethods = _paymentMethods
                    })
                })
                
                //This account supports paypal
                expect {
                    return paymentMethods?.supportsPaypal
                }.toEventually(equal(true))
                
                //This account supports credit cards
                expect {
                    return paymentMethods?.supportsCreditCard
                }.toEventually(equal(true))
                
                //Paypal should be configured with 'adaptive' in the config.processor_information.paypal.api
                expect {
                    let paypalInfo = paymentMethods?.processorInfo?["paypal"] as? [String:AnyObject]
                    let api = paypalInfo?["api"] as? String
                    
                    return api
                }.toEventually(equal("adaptive"))
            }
        }
    }
}