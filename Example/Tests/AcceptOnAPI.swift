// https://github.com/Quick/Quick

import Quick
import Nimble
import accepton

class AcceptOnAPISpec: QuickSpec {
    override func spec() {
        describe("init") {
            it("can be created with a public or secret key") {
                let api = AcceptOnAPI.init(publicKey: "test")
                expect(api.accessToken) == "test"
                
                let api2 = AcceptOnAPI.init(secretKey: "test2")
                expect(api2.accessToken) == "test2"
            }
            
//            it("can do maths") {
//                expect(1) == 2
//            }
//
//            it("can read") {
//                expect("number") == "string"
//            }
//
//            it("will eventually fail") {
//                expect("time").toEventually( equal("done") )
//            }
        }
    }
}
