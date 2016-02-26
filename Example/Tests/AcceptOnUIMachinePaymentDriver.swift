// https://github.com/Quick/Quick

import Quick
import Nimble
import accepton

//Handle payment driver response
class AcceptOnUIMachinePaymentDriverDelegateStub: AcceptOnUIMachinePaymentDriverDelegate {
    func transactionDidFailForDriver(driver: AcceptOnUIMachinePaymentDriver, withMessage message: String) {
        
    }
    
    //Transaction has completed
    func transactionDidSucceedForDriver(driver: AcceptOnUIMachinePaymentDriver, withChargeRes chargeRes: [String:AnyObject]){
        
    }
    
    func transactionDidCancelForDriver(driver: AcceptOnUIMachinePaymentDriver){
        
    }
    
    let api: AcceptOnAPI
    init(api: AcceptOnAPI) {
        self.api = api
    }
}

//The dummy payment driver
class AcceptOnUIMachinePaymentDummyDriver: AcceptOnUIMachinePaymentDriver {
    override func beginTransaction() {
        
    }
}

class AcceptOnUIMachinePaymentDriverSpec: QuickSpec {
    override func spec() {
        AcceptOnAPIFactory.query.withAtleast(.Sandbox).each { apiInfo, desc in
            context(desc) {
                var paymentDelegate: AcceptOnUIMachinePaymentDriverDelegateStub {
                    return AcceptOnUIMachinePaymentDriverDelegateStub(api: apiInfo.api)
                }
                
                AcceptOnUIMachineFormOptionsFactory.withAtleast(.SupportsCreditCards, .Bogus).each { formOptions, formOptionsDesc in
                    let paymentDelegateStrong = paymentDelegate
                    context(formOptionsDesc) {
                        var dummyDriver: AcceptOnUIMachinePaymentDriver {
                            let driver = AcceptOnUIMachinePaymentDriver(formOptions: formOptions)
                            driver.delegate = paymentDelegateStrong
                            return driver
                        }
                        
                        it("does fail") {
                            let driver = dummyDriver
                            driver.beginTransaction()
                        }
                    }
                }
                
//                var stripePaymentDriver: AcceptOnUIMachinePaymentDriver {
//                    return AcceptOnUIMachine
//                }
            }
        }
    }
}