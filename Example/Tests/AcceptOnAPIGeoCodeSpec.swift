// https://github.com/Quick/Quick

import Quick
import Nimble
import accepton

//Relating to geo-code part of API
class AcceptOnAPIGeoCodeSpec: QuickSpec {
    override func spec() {
        describe("autocomplete") {
            it("can autocomplete a request through the geocode API") {
                let api = AcceptOnAPI.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                var addresses: [(description: String, placeId: String)]?
                
                api.autoCompleteAddress("685 Whisper") { _addresses, err in
                    addresses = _addresses
                }
                
                //Should return at least one address
                expect {
                    return addresses == nil
                }.toEventually(equal(false))
            }
            
            it("can resolve the autcompleted request to an address through the geocode API") {
                let api = AcceptOnAPI.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                var address: AcceptOnAPIAddress?
                
                api.autoCompleteAddress("685 Whisper") { _addresses, err in
                    api.convertPlaceIdToAddress(_addresses![0].placeId, completion: { (_address, err) -> () in
                        address = _address
                    })
                }
                
                //Should be able to get an address back
                expect {
                    return address == nil
                }.toEventually(equal(false))
                
                //Street should have some characters in it
                expect {
                    return address?.street.characters.count ?? -1
                }.toEventually(beGreaterThan(0))
            }
        }
    }
}