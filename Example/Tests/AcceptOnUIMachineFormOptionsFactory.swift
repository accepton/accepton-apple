import accepton

enum AcceptOnUIMachineFormOptionsFactoryProperty: Equatable {
    case Default
    
    case Bogus
    case SupportsCreditCards
}

//func ==(lhs: AcceptOnUIMachineFormOptionsFactoryProperty, rhs: AcceptOnUIMachineFormOptionsFactoryProperty) -> Bool {
//    switch (lhs, rhs) {
//    case (.Item, .Item):
//        return true
//    default:
//        return false
//    }
//}

class AcceptOnUIMachineFormOptionsFactory: Factory<AcceptOnUIMachineFormOptions, AcceptOnUIMachineFormOptionsFactoryProperty> {
    required init() {
        super.init()
        
        self.context(.Bogus) {
            AcceptOnAPITransactionTokenFactory.withAtleast(.Bogus).each { transactionToken, tokenDesc in
                self.context(withExtraDescs: ["token": tokenDesc]) {
                    
                    self.context(.SupportsCreditCards) {
                        AcceptOnAPIPaymentMethodsInfoFactory.withAtleast(.PaymentMethodCreditCard).each { paymentMethodsInfo, paymentMethodDesc in
                            self.product(withExtraDescs: ["payment_methods": paymentMethodDesc]) {
                                return AcceptOnUIMachineFormOptions(token: transactionToken, paymentMethods: paymentMethodsInfo)
                            }
                        }
                    }
                }
            }}
    }
}