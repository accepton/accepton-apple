// https://github.com/Quick/Quick

import Quick
import Nimble
import accepton

//Handle payment driver response
class AcceptOnUIMachinePaymentDriverDelegateStub: Spy, AcceptOnUIMachinePaymentDriverDelegate {
    var callLog: [(name: String, args: [String:AnyObject])] = []
    
    func transactionDidFailForDriver(driver: AcceptOnUIMachinePaymentDriver, withMessage message: String) {
        logCall("transactionDidFailForDriver:withMessage:", withArgs: [
            "driver": driver,
            "withMessage": message
            ])
    }
    
    //Transaction has completed
    func transactionDidSucceedForDriver(driver: AcceptOnUIMachinePaymentDriver, withChargeRes chargeRes: [String:AnyObject]){
        logCall("transactionDidSucceedForDriver:withChargeRes:", withArgs: [
            "driver": driver,
            "withChargeRes": chargeRes
            ])
    }
    
    func transactionDidCancelForDriver(driver: AcceptOnUIMachinePaymentDriver) {
        logCall("transactionDidCancelForDriver:", withArgs: [
            "driver": driver
            ])
    }
    
    var api: AcceptOnAPI {
        return apiSpy
    }
    
    var apiSpy: AcceptOnAPISpy
    
    init(api: AcceptOnAPI) {
        self.apiSpy = AcceptOnAPISpy(api)
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
                
                //If the form options support credit-cards but we have all bogus payment processor info (stripe, brain-tree, etc will fail)
                AcceptOnUIMachineFormOptionsFactory.withAtleast(.SupportsCreditCards, .Bogus).each { formOptions, formOptionsDesc in
                    context(formOptionsDesc) {
                        it("does attempt to send credit-card information") {
                            let paymentDelegate = paymentDelegate
                            let driver = AcceptOnUIMachineCreditCardDriver(formOptions: formOptions)
                            driver.delegate = paymentDelegate
                            driver.beginTransaction()
                            
                            expect(paymentDelegate.apiSpy).toEventually(haveInvoked("chargeWithTransactionId:andChargeInfo:", withMatchingArgExpression: {
                                let chargeInfo = $0["chargeInfo"] as! AcceptOnAPIChargeInfo
                                if chargeInfo.rawCardInfo?.number == formOptions.creditCardParams?.number { return true }
                                return false
                            }))
                        }
                    }
                }
            }
        }
    }
}