//// https://github.com/Quick/Quick
//
//import Quick
//import Nimble
//import accepton
//
//class AcceptOnAPICreditCardParamsSpec: QuickSpec {
//    override func spec() {
//        describe("mergeIntoParams") {
//            AcceptOnAPICreditCardParamsFactory.query.withAtleast(.FourTwoPattern).each { card, desc in
//                context(desc) {
//                    it("does merge correctly") {
//                        var info: [String:AnyObject] = [:]
//                        card.mergeIntoParams(&info)
//                        
//                        expect(info["number"] as? String).to(equal(card.number))
//                        expect(info["exp_month"] as? String).to(equal(card.expMonth))
//                        expect(info["exp_year"] as? String).to(equal(card.expYear))
//                        expect(info["security_code"] as? String).to(equal(card.cvc))
//                    }
//                }
//            }
//        }
//    }
//}