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
        
        AcceptOnAPICreditCardParamsFactory.query.withAtleast(.FourTwoPattern).each { card, cardDesc in
            self.product(.HasRawCreditCardParams, withExtraDesc: ["card": cardDesc]) {
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
                    AcceptOnAPICreditCardParamsFactory.query.withAtleast(.FourTwoPattern).each { card, cardDesc in
                        self.product(withExtraDesc: ["card": cardDesc]) {
                            return AcceptOnAPIChargeInfo(rawCardInfo: card, cardTokens: cardTokens, email: nil, metadata: [:])
                        }
                    }
                }
            }
        }
    }
}