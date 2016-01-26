// https://github.com/Quick/Quick

import Quick
import Nimble
import accepton

//Relating to the information returned by the API for certain payment processors that
//should be enabled
class AcceptOnPaymentProcessorSpec: QuickSpec {
    override func spec() {
        describe("paypal") {
            it("Can retrieve the paypal rest client secret") {
                let apiKey = apiKeyWithProperties([.PaypalRest], withoutProperties: [])
                let api = AcceptOnAPI(publicKey: apiKey.key, isProduction: false)
                
                var _paymentMethods: AcceptOnAPIPaymentMethodsInfo?
                api.createTransactionTokenWithDescription("Foo", forAmountInCents: 100, completion: { (token, error) -> () in
                    if error != nil {
                        NSException(name: "createTransactionTokenWithDescription", reason: error!.description, userInfo: nil).raise()
                        return
                    }
                    
                    api.getAvailablePaymentMethodsForTransactionWithId(token!.id, completion: { (paymentMethods, error) -> () in
                        if error != nil {
                            NSException(name: "getAvailablePaymentMethodsForTransactionWithId", reason: error!.description, userInfo: nil).raise()
                            return
                        }
                        
                        _paymentMethods = paymentMethods!
                    })
                })
                
                expect(_paymentMethods?.supportsPaypal).toEventually(equal(true))
            }
        }
        
        describe("apple_pay") {
            it("Does get supportsApplePay == false for a non apple-pay enabled account") {
                let apiKey = apiKeyWithProperties([], withoutProperties: [.ApplePay])
                let api = AcceptOnAPI(publicKey: apiKey.key, isProduction: false)
                
                var _paymentMethods: AcceptOnAPIPaymentMethodsInfo?
                api.createTransactionTokenWithDescription("Foo", forAmountInCents: 100, completion: { (token, error) -> () in
                    if error != nil {
                        NSException(name: "createTransactionTokenWithDescription", reason: error!.description, userInfo: nil).raise()
                        return
                    }
                    
                    api.getAvailablePaymentMethodsForTransactionWithId(token!.id, completion: { (paymentMethods, error) -> () in
                        if error != nil {
                            NSException(name: "getAvailablePaymentMethodsForTransactionWithId", reason: error!.description, userInfo: nil).raise()
                            return
                        }
                        
                        _paymentMethods = paymentMethods!
                    })
                })
                
                expect(_paymentMethods?.supportsApplePay).toEventually(equal(false))
            }
        }
        
        it("Does get supportsApplePay == true for an apple-pay enabled account") {
            let apiKey = apiKeyWithProperties([.ApplePay], withoutProperties: [])
            let api = AcceptOnAPI(publicKey: apiKey.key, isProduction: false)
            
            var _paymentMethods: AcceptOnAPIPaymentMethodsInfo?
            api.createTransactionTokenWithDescription("Foo", forAmountInCents: 100, completion: { (token, error) -> () in
                if error != nil {
                    NSException(name: "createTransactionTokenWithDescription", reason: error!.description, userInfo: nil).raise()
                    return
                }
                
                api.getAvailablePaymentMethodsForTransactionWithId(token!.id, completion: { (paymentMethods, error) -> () in
                    if error != nil {
                        NSException(name: "getAvailablePaymentMethodsForTransactionWithId", reason: error!.description, userInfo: nil).raise()
                        return
                    }
                    
                    _paymentMethods = paymentMethods!
                })
            })
            
            expect(_paymentMethods?.supportsApplePay).toEventually(equal(true))
        }
        
        it("Does get stripeApplePayMerchantIdentifier for an account that has stripe & apple-pay integration enabled") {
            let apiKey = apiKeyWithProperties([.ApplePay], withoutProperties: [])
            let api = AcceptOnAPI(publicKey: apiKey.key, isProduction: false)
            
            var _paymentMethods: AcceptOnAPIPaymentMethodsInfo?
            api.createTransactionTokenWithDescription("Foo", forAmountInCents: 100, completion: { (token, error) -> () in
                if error != nil {
                    NSException(name: "createTransactionTokenWithDescription", reason: error!.description, userInfo: nil).raise()
                    return
                }
                
                api.getAvailablePaymentMethodsForTransactionWithId(token!.id, completion: { (paymentMethods, error) -> () in
                    if error != nil {
                        NSException(name: "getAvailablePaymentMethodsForTransactionWithId", reason: error!.description, userInfo: nil).raise()
                        return
                    }
                    
                    _paymentMethods = paymentMethods!
                })
            })
            
            expect(_paymentMethods?.stripeApplePayMerchantIdentifier).toEventually(equal(apiKey.metadata["stripe_merchant_identifier"] as? String))
        }
    }
}