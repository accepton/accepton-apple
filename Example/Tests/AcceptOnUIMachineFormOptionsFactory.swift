import accepton

enum AcceptOnUIMachineFormOptionsFactoryProperty {
    case Default
    
    case Bogus
    case SupportsCreditCards
    
    case SupportsNoCreditCardPaymentProcessors
}

class AcceptOnUIMachineFormOptionsFactory: Factory<AcceptOnUIMachineFormOptions, AcceptOnUIMachineFormOptionsFactoryProperty> {
    required init() {
        super.init()
        
        self.context(.Bogus) {
            //Get transaction tokens available (product descriptions)
            AcceptOnAPITransactionTokenFactory.withAtleast(.Bogus).each { transactionToken, tokenDesc in
                self.context(withExtraDescs: ["token": tokenDesc]) {
                    
                    //All of these products have raw credit-card information bound to them
                        AcceptOnAPICreditCardParamsFactory.withAtleast(.FourTwoPattern).each { card, cardDesc in
                            self.context(.SupportsCreditCards, withExtraDescs: ["cardDesc": cardDesc]) {
                                
                                //Create form options for supporting credit-card processing but no particular payment processor (usually for Authorize.net)
                                AcceptOnAPIPaymentMethodsInfoFactory.withAtleast(.SupportsCreditCards, .WithoutAnyCreditCardPaymentProcessors).each { paymentMethodsInfo, paymentMethodDesc in
                                    self.product(.SupportsNoCreditCardPaymentProcessors, withExtraDescs: ["card_desc": cardDesc, "payment_methods": paymentMethodDesc]) {
                                        let formOptions = AcceptOnUIMachineFormOptions(token: transactionToken, paymentMethods: paymentMethodsInfo)
                                        formOptions.creditCardParams = card
                                        
                                        return formOptions
                                    }
                                }
                                
                                //Create form options for supporting some number of payment processors
                                AcceptOnAPIPaymentMethodsInfoFactory.withAtleast(.SupportsCreditCards).without(.WithoutAnyCreditCardPaymentProcessors).each { paymentMethodsInfo, paymentMethodDesc in
                                    self.product(withExtraDescs: ["card_desc": cardDesc, "payment_methods": paymentMethodDesc]) {
                                        let formOptions = AcceptOnUIMachineFormOptions(token: transactionToken, paymentMethods: paymentMethodsInfo)
                                        formOptions.creditCardParams = card
                                        
                                        return formOptions
                                    }
                                }

                            }
                        }
                }
            }
        }
    }
}