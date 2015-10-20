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
        }
        
        describe("createToken") {
            it("does fail with Unauthorized if a fake access token is given") {
                let api = AcceptOnAPI.init(publicKey: "no_such_token")
                var error: NSError? = nil
                api.createTransactionTokenWithDescription("No Such T-Shirt", forAmountInCents: 100, completion: { (tokenRes, _error) -> () in
                    error = _error
                })
                
                expect {
                    return error?.code
                }.toEventually(equal(AcceptOnAPIError.Code.Unauthorized.rawValue))
            }
            
            it("does retrieve a transaction token when a working access token is given") {
                let api = AcceptOnAPI.init(publicKey: "pkey_24b6fa78e2bf234d")
                var tokenRes: [String: AnyObject]? = nil
                api.createTransactionTokenWithDescription("T-Shirt", forAmountInCents: 100, completion: { (_tokenRes, _error) -> () in
                    tokenRes = _tokenRes
                })
                
                expect {
                    return tokenRes?["id"] as? String
                }.toEventually(contain("txn"))
            }
        }
    }
}