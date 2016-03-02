// https://github.com/Quick/Quick

import Quick
import Nimble
import accepton

//Relating to the information returned by the API for certain payment processors that
//should be enabled
class AcceptOnPaymentProcessorSpec: QuickSpec {
    override func spec() {
        describe("paypal") {
            AcceptOnAPIFactory.query.withAtleast(.PaypalRest, .Sandbox).each { apiInfo, desc in
                context(desc) {
                    it("Can retrieve the paypal rest client secret") {
                        var _paymentMethods: AcceptOnAPIPaymentMethodsInfo?
                        apiInfo.api.createTransactionTokenWithDescription("Foo", forAmountInCents: 100, completion: { (token, error) -> () in
                            if error != nil {
                                NSException(name: "createTransactionTokenWithDescription", reason: error!.description, userInfo: nil).raise()
                                return
                            }
                            
                            apiInfo.api.getAvailablePaymentMethodsForTransactionWithId(token!.id, completion: { (paymentMethods, error) -> () in
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
            }
        }
        
        describe("apple_pay") {
            AcceptOnAPIFactory.query.withAtleast(.Sandbox).without(.ApplePayStripe).each { apiInfo, desc in
                context(desc) {
                    it("Does get supportsApplePay == false for a non apple-pay enabled account") {
                        var _paymentMethods: AcceptOnAPIPaymentMethodsInfo?
                        apiInfo.api.createTransactionTokenWithDescription("Foo", forAmountInCents: 100, completion: { (token, error) -> () in
                            if error != nil {
                                NSException(name: "createTransactionTokenWithDescription", reason: error!.description, userInfo: nil).raise()
                                return
                            }
                            
                            apiInfo.api.getAvailablePaymentMethodsForTransactionWithId(token!.id, completion: { (paymentMethods, error) -> () in
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
            }
        }
        
        describe("braintree") {
            AcceptOnAPIFactory.query.withAtleast(.Sandbox).withAtleast(.Braintree).each { apiInfo, desc in
                context(desc) {
                    it("Does get supportsBrainTree == true for a brain-tree enabled account and a nonce") {
                        var _paymentMethods: AcceptOnAPIPaymentMethodsInfo?
                        apiInfo.api.createTransactionTokenWithDescription("Foo", forAmountInCents: 100, completion: { (token, error) -> () in
                            if error != nil {
                                NSException(name: "createTransactionTokenWithDescription", reason: error!.description, userInfo: nil).raise()
                                return
                            }
                            
                            apiInfo.api.getAvailablePaymentMethodsForTransactionWithId(token!.id, completion: { (paymentMethods, error) -> () in
                                if error != nil {
                                    NSException(name: "getAvailablePaymentMethodsForTransactionWithId", reason: error!.description, userInfo: nil).raise()
                                    return
                                }
                                
                                _paymentMethods = paymentMethods!
                            })
                        })
                        
                        expect(_paymentMethods?.supportsBraintree).toEventually(equal(true))
                        expect(_paymentMethods?.braintreeMerchantId).toEventuallyNot(equal(nil))
                        expect(_paymentMethods?.braintreeClientAuthorizationFingerprint).toEventuallyNot(equal(nil))
                    }
                    
                    it("Does allow Braintree to process a sandbox credit-card") {
                        
                    }
                }
            }
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