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
                let api = AcceptOnAPI(publicKey: apiKey, isProduction: false)
                
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
    }
}