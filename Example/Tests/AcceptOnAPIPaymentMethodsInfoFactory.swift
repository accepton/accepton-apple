import accepton

enum AcceptOnAPIPaymentMethodsInfoFactoryProperty: Equatable {
    case Stripe(key: String?, isBogus: Bool)
    case PayPalRest(key: String?, isBogus: Bool)
    case Braintree(key: String?, isBogus: Bool)
    
    case SupportsCreditCards
    
    case WithoutAnyCreditCardPaymentProcessors
    
    case Bogus    //All security tokens, etc are 100% bogus
    case Sandbox  //Tokens are valid and pulled from a server (but are sandboxed versions)
}

//This allows you to search via bogus/non-bogus keys
func ==(lhs: AcceptOnAPIPaymentMethodsInfoFactoryProperty, rhs: AcceptOnAPIPaymentMethodsInfoFactoryProperty) -> Bool {
    switch (lhs, rhs) {
    case (.Stripe(_, let bl), .Stripe(_, let br)) where bl == br:
        return true
    case (.PayPalRest(_, let bl), .Stripe(_, let br)) where bl == br:
        return true
    case (.Braintree(_, let bl), .Braintree(_, let br)) where bl == br:
        return true
    case (.SupportsCreditCards, .SupportsCreditCards):
        return true
    case (.WithoutAnyCreditCardPaymentProcessors, .WithoutAnyCreditCardPaymentProcessors): return true
    case (.Bogus, .Bogus): return true
    case (.Sandbox, .Sandbox): return true
    default:
        return false
    }
}

struct AcceptOnAPIPaymentMethodsInfoFactoryResult {
    let paymentMethodsInfo: AcceptOnAPIPaymentMethodsInfo
    let transactionTokenFactoryResult: AcceptOnAPITransactionTokenFactoryResult!
    
    init(_ paymentMethodsInfo: AcceptOnAPIPaymentMethodsInfo) {
        self.paymentMethodsInfo = paymentMethodsInfo
        self.transactionTokenFactoryResult = nil
    }
    
    init(paymentMethodsInfo: AcceptOnAPIPaymentMethodsInfo, transactionTokenFactoryRes: AcceptOnAPITransactionTokenFactoryResult) {
        self.paymentMethodsInfo = paymentMethodsInfo
        self.transactionTokenFactoryResult = transactionTokenFactoryRes
    }
}

class AcceptOnAPIPaymentMethodsInfoFactory: Factory<AcceptOnAPIPaymentMethodsInfoFactoryResult, AcceptOnAPIPaymentMethodsInfoFactoryProperty> {
    required init() {
        super.init()
        
        context(.SupportsCreditCards, .Bogus) {
            self.product(.WithoutAnyCreditCardPaymentProcessors) {
                AcceptOnAPIPaymentMethodsInfoFactoryResult(AcceptOnAPIPaymentMethodsInfo.parseConfig([
                    "payment_methods": ["credit-card"],
                    "processor_information": [
                        "credit-card": []
                    ]
                ])!)
            }
            
            var stripePublishableKey: String { return "bogus-stripe-publishable-key-xxxxx>" }
            self.context(.Stripe(key: stripePublishableKey, isBogus: true)) {
                self.product {
                    AcceptOnAPIPaymentMethodsInfoFactoryResult(
                    AcceptOnAPIPaymentMethodsInfo.parseConfig([
                        "payment_methods": ["credit-card"],
                        "processor_information": [
                            "credit-card": [
                                "stripe": ["publishable_key": stripePublishableKey]
                            ]
                        ]
                    ])!)
                }
            }
            
            var paypalClientId: String { return "bogus-paypal-client-id-xxxxx" }
            self.context(.PayPalRest(key: paypalClientId, isBogus: true)) {
                self.product {
                    AcceptOnAPIPaymentMethodsInfoFactoryResult(
                    AcceptOnAPIPaymentMethodsInfo.parseConfig([
                        "payment_methods": ["credit-card"],
                        "processor_information": [
                            "credit-card": [
                                "paypal_rest": ["client_id": paypalClientId]
                            ]
                        ]
                    ])!)
                }
            }
        }
        
        context(.Sandbox) {
            AcceptOnAPITransactionTokenFactory.withAtleast(.Sandbox).each { tokenInfo, desc in
                self.product(properties: [], withExtraDesc: ["tokenDesc": desc]) {
                    let sem = dispatch_semaphore_create(0)
                    
                    var paymentMethodsRes: AcceptOnAPIPaymentMethodsInfo!
                    tokenInfo.api!.getAvailablePaymentMethodsForTransactionWithId(tokenInfo.token.id, completion: { (paymentMethods, error) -> () in
                        paymentMethodsRes = paymentMethods
                        
                        dispatch_semaphore_signal(sem)
                    })
                    
                    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
                    
                    return AcceptOnAPIPaymentMethodsInfoFactoryResult(paymentMethodsInfo: paymentMethodsRes, transactionTokenFactoryRes: tokenInfo)
                }
            }
        }
    }
}