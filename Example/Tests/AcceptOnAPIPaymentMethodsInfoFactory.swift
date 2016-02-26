import accepton

enum AcceptOnAPIPaymentMethodsInfoFactoryProperty: Equatable {
    case Stripe(key: String?, isBogus: Bool)
    case PayPalRest(key: String?, isBogus: Bool)
    
    case PaymentMethodCreditCard
}

//This allows you to search via bogus/non-bogus keys
func ==(lhs: AcceptOnAPIPaymentMethodsInfoFactoryProperty, rhs: AcceptOnAPIPaymentMethodsInfoFactoryProperty) -> Bool {
    switch (lhs, rhs) {
    case (.Stripe(_, let bl), .Stripe(_, let br)) where bl == br:
        return true
    case (.PayPalRest(_, let bl), .Stripe(_, let br)) where bl == br:
        return true
    case (.PaymentMethodCreditCard, .PaymentMethodCreditCard):
        return true
    default:
        return false
    }
}

class AcceptOnAPIPaymentMethodsInfoFactory: Factory<AcceptOnAPIPaymentMethodsInfo, AcceptOnAPIPaymentMethodsInfoFactoryProperty> {
    required init() {
        super.init()
        
        context(.PaymentMethodCreditCard) {
            self.product {
                AcceptOnAPIPaymentMethodsInfo.parseConfig([
                    "payment_methods": ["credit-card"],
                    "processor_information": [
                        "credit-card": []
                    ]
                ])!
            }
            
            var stripePublishableKey: String { return "bogus-stripe-publishable-key-xxxxx>" }
            self.context(.Stripe(key: stripePublishableKey, isBogus: true)) {
                self.product {
                    AcceptOnAPIPaymentMethodsInfo.parseConfig([
                        "payment_methods": ["credit-card"],
                        "processor_information": [
                            "credit-card": [
                                "stripe": ["publishable_key": stripePublishableKey]
                            ]
                        ]
                    ])!
                }
            }
            
            var paypalClientId: String { return "bogus-paypal-client-id-xxxxx" }
            self.context(.PayPalRest(key: paypalClientId, isBogus: true)) {
                self.product {
                    AcceptOnAPIPaymentMethodsInfo.parseConfig([
                        "payment_methods": ["credit-card"],
                        "processor_information": [
                            "credit-card": [
                                "paypal_rest": ["client_id": paypalClientId]
                            ]
                        ]
                    ])!
                }
            }
        }
    }
}