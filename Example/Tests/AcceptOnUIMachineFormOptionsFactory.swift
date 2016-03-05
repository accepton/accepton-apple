import accepton

enum AcceptOnUIMachineFormOptionsFactoryProperty {
    case Default
    
    case Bogus    //All security tokens, etc are 100% bogus
    case Sandbox  //Tokens are valid and pulled from a server (but are sandboxed versions)
    
    case SupportsCreditCards
    
    case SupportsNoCreditCardPaymentProcessors
}

struct AcceptOnUIMachineFormOptionsFactoryResult {
    let formOptions: AcceptOnUIMachineFormOptions
    let api: AcceptOnAPI!
}

class AcceptOnUIMachineFormOptionsFactory: Factory<AcceptOnUIMachineFormOptionsFactoryResult, AcceptOnUIMachineFormOptionsFactoryProperty> {
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
                                        let formOptions = AcceptOnUIMachineFormOptions(token: transactionToken.token, paymentMethods: paymentMethodsInfo.paymentMethodsInfo)
                                        formOptions.creditCardParams = card
                                        
                                        return AcceptOnUIMachineFormOptionsFactoryResult(formOptions: formOptions, api: nil)
                                    }
                                }
                                
                                //Create form options for supporting some number of payment processors
                                AcceptOnAPIPaymentMethodsInfoFactory.withAtleast(.SupportsCreditCards).without(.WithoutAnyCreditCardPaymentProcessors).each { paymentMethodsInfo, paymentMethodDesc in
                                    self.product(withExtraDescs: ["card_desc": cardDesc, "payment_methods": paymentMethodDesc]) {
                                        let formOptions = AcceptOnUIMachineFormOptions(token: transactionToken.token, paymentMethods: paymentMethodsInfo.paymentMethodsInfo)
                                        formOptions.creditCardParams = card
                                        
                                        return AcceptOnUIMachineFormOptionsFactoryResult(formOptions: formOptions, api: nil)
                                    }
                                }
                            }
                        }
                }
            }
        }
        
        self.context(.Sandbox) {
            //All of these products have raw credit-card information bound to them
            AcceptOnAPICreditCardParamsFactory.withAtleast(.FourTwoPattern).each { card, cardDesc in
                self.context(.SupportsCreditCards, withExtraDescs: ["cardDesc": cardDesc]) {
                    
                    //Braintree
                    //⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐⤐
                    AcceptOnAPIPaymentMethodsInfoFactory.withAtleast(.Sandbox).each { paymentMethodsInfo, paymentMethodDesc in
                        self.product(withExtraDescs: ["payment_methods": paymentMethodDesc]) {
                            let formOptions = AcceptOnUIMachineFormOptions(token: paymentMethodsInfo.transactionTokenFactoryResult.token, paymentMethods: paymentMethodsInfo.paymentMethodsInfo)
                            formOptions.creditCardParams = card
                            
                            return AcceptOnUIMachineFormOptionsFactoryResult(formOptions: formOptions, api: paymentMethodsInfo.transactionTokenFactoryResult.api!)
                        }
                    }
                }
            }
        }
    }
}