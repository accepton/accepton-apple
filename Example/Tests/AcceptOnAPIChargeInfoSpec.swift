// https://github.com/Quick/Quick

import Quick
import Nimble
import accepton

func beAComplaintCardFieldForAcceptOnAPIWithCard(card: AcceptOnAPICreditCardParams) -> NonNilMatcherFunc<[String:AnyObject]> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "represent complaint 'card' field for AcceptOn /v1/Charges endpoint for given raw credit-card parameters."

        if let cardInfo = try actualExpression.evaluate() {
            guard let number = cardInfo["number"] as? String where number == card.number else {
                failureMessage.postfixMessage += " The cardInfo field 'number' was non-existant"
                return false
            }
            
            guard let expMonth = cardInfo["exp_month"] as? String where expMonth == card.expMonth else {
                failureMessage.postfixMessage += " The cardInfo field 'expMonth' was non-existant"
                return false
            }
            
            guard let expYear = cardInfo["exp_year"] as? String where expYear == card.expYear else {
                failureMessage.postfixMessage += " The cardInfo field 'expYear' was non-existant"
                return false
            }
            
            guard let security = cardInfo["security_code"] as? String where security == card.cvc else {
                failureMessage.postfixMessage += " The cardInfo field 'security_code' was non-existant"
                return false
            }
            
            return true
        } else { return false }
    }
}

class AcceptOnAPIChargeInfoSpec: QuickSpec {
    override func spec() {
        describe("mergeIntoParams") {
            context("when only the raw card information is given") {
                AcceptOnAPIChargeInfoFactory.query.withAtleast(.HasRawCreditCardParams).without(.HasTokens).each { chargeInfo, desc in
                    context(desc) {
                        it("does merge with correct card parameters") {
                            var info: [String:AnyObject] = [:]
                            chargeInfo.mergeIntoParams(&info)
                            
                            let card = chargeInfo.rawCardInfo!
                            let cardInfo = info["card"] as? [String:AnyObject]
                            expect(cardInfo).to(beAComplaintCardFieldForAcceptOnAPIWithCard(card))
                            
                            expect(info["card_tokens"]?.count).to(equal(0))
                        }
                    }
                }
            }
            
            context("When only tokens are given") {
                AcceptOnAPIChargeInfoFactory.query.withAtleast(.HasTokens).without(.HasRawCreditCardParams).each { chargeInfo, desc in
                    context(desc) {
                        it("does merge with correct card parameters") {
                            var info: [String:AnyObject] = [:]
                            chargeInfo.mergeIntoParams(&info)
                            
                            var cardTokens = info["card_tokens"] as! [String:String]
                            for (tokenSource, token) in chargeInfo.cardTokens! { expect(cardTokens[tokenSource]).to(equal(token as! String)) }
                            
                            expect(info["card"]).to(beNil())
                        }
                    }
                }
            }
            
            context("When tokens and raw-card-info is given") {
                AcceptOnAPIChargeInfoFactory.query.withAtleast(.HasTokens).without(.HasRawCreditCardParams).each { chargeInfo, desc in
                    context(desc) {
                        it("does merge with correct token parameters") {
                            var info: [String:AnyObject] = [:]
                            chargeInfo.mergeIntoParams(&info)
                            
                            var cardTokens = info["card_tokens"] as! [String:String]
                            for (tokenSource, token) in chargeInfo.cardTokens! { expect(cardTokens[tokenSource]).to(equal(token as! String)) }
                            
                            expect(info["card"]).to(beNil())
                        }
                    }
                }
            }
            
            context("When neither tokens or raw-card-info is given") {
                AcceptOnAPIChargeInfoFactory.query.without(.HasRawCreditCardParams, .HasTokens).each { chargeInfo, desc in
                    context(desc) {
                        it("does merge with correct token parameters") {
                            var info: [String:AnyObject] = [:]
                            chargeInfo.mergeIntoParams(&info)
                            
                            let cardTokens = info["card_tokens"] as! [String:String]
                            expect(cardTokens.count).to(equal(0))
                            expect(info["card"]).to(beNil())
                        }
                    }
                }
            }

        }
    }
}