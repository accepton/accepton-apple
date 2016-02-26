import accepton

enum AcceptOnAPIChargeInfoFactoryProperty {
    case HasTokens
    case HasInvalidStripeToken
    case HasEmail
    case HasRawCreditCardParams
}

class AcceptOnAPIChargeInfoFactory: Factory<AcceptOnAPIChargeInfo, AcceptOnAPIChargeInfoFactoryProperty> {
    required init() {
        super.init()
        
        var cardTokens: [String:AnyObject] { return [:] }
        var card: AcceptOnAPICreditCardParams?
        
        self.product {
            return AcceptOnAPIChargeInfo(rawCardInfo: card, cardTokens: cardTokens, email: nil, metadata: [:])
        }
        
        AcceptOnAPICreditCardParamsFactory.withAtleast(.FourTwoPattern).each { card, cardDesc in
            self.product(.HasRawCreditCardParams, withExtraDescs: ["card": cardDesc]) {
                return AcceptOnAPIChargeInfo(rawCardInfo: card, cardTokens: cardTokens, email: nil, metadata: [:])
            }
        }
        
        context(.HasTokens) {
            self.context(.HasInvalidStripeToken) {
                var cardTokens: [String:AnyObject] { return ["stripe":"xxx"] }
                self.product {
                    return AcceptOnAPIChargeInfo(cardTokens: cardTokens, email: nil, metadata: [:])
                }
                
                self.context(.HasRawCreditCardParams) {
                    AcceptOnAPICreditCardParamsFactory.withAtleast(.FourTwoPattern).each { card, cardDesc in
                        self.product(withExtraDescs: ["card": cardDesc]) {
                            return AcceptOnAPIChargeInfo(rawCardInfo: card, cardTokens: cardTokens, email: nil, metadata: [:])
                        }
                    }
                }
            }
        }
    }
}