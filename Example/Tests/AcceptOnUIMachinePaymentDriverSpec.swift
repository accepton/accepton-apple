// https://github.com/Quick/Quick

import Quick
import Nimble
import accepton

//Handle payment driver response
class AcceptOnUIMachinePaymentDriverDelegateStub: Spy, AcceptOnUIMachinePaymentDriverDelegate {
    var callLog: [(name: String, args: [String:AnyObject])] = []
    
    @objc func transactionDidFailForDriver(driver: AcceptOnUIMachinePaymentDriver, withMessage message: String) {
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
//        AcceptOnAPIFactory.query.withAtleast(.Sandbox).each { apiInfo, desc in
//            context(desc) {
//                
//                //If the form options support credit-cards but we have all bogus payment processor info (stripe, brain-tree, etc will fail)
//                AcceptOnUIMachineFormOptionsFactory.withAtleast(.SupportsCreditCards, .Bogus).each { formOptionsRes, formOptionsDesc in
//                    context(formOptionsDesc) {
//                        it("does attempt to send credit-card information") {
//                            let _paymentDelegate = AcceptOnUIMachinePaymentDriverDelegateStub(api: apiInfo.api)
//                            let driver = AcceptOnUIMachineCreditCardDriver(formOptions: formOptionsRes.formOptions)
//                            driver.delegate = _paymentDelegate
//                            driver.beginTransaction()
//                            
//                            expect {
//                                let delegate = driver.delegate
//                                let api = delegate.api as! AcceptOnAPISpy
//                                return api
//                                
//                            }.toEventually(haveInvoked("chargeWithTransactionId:andChargeInfo:", withMatchingArgExpression: {
//                                
//                                let _keep = _paymentDelegate
//                                let _keep2 = driver
//                                let chargeInfo = $0["chargeInfo"] as! AcceptOnAPIChargeInfo
//                                if chargeInfo.rawCardInfo?.number == formOptionsRes.formOptions.creditCardParams?.number { return true }
//                                return false
//                            }), timeout: 20)
//                        }
//                    }
//                }
//            }
//        }
        
        AcceptOnUIMachineFormOptionsFactory.withAtleast(.SupportsCreditCards, .Sandbox).each { formOptionsRes, formOptionsDesc in
            context(formOptionsDesc) {
                if formOptionsRes.formOptions.paymentMethods.supportsBraintree {
                    it("does attempt and suceed with authorizing credit-card") {
                        let paymentDelegate = AcceptOnUIMachinePaymentDriverDelegateStub(api: formOptionsRes.api)
                        let driver = AcceptOnUIMachineCreditCardDriver(formOptions: formOptionsRes.formOptions)
                        driver.delegate = paymentDelegate
                        driver.beginTransaction()
                        
                    
                        expect(paymentDelegate).toEventually(haveInvoked("transactionDidSucceedForDriver:withChargeRes:", withMatchingArgExpression: {
                        let driver = $0["driver"] as! AcceptOnUIMachinePaymentDriver
                        let _keep1 = paymentDelegate
                        let _keep2 = driver
                        if let braintreeNonce = driver.nonceTokens["braintree"] {
                            return true
                        }
                        
                        return false
                        }), timeout: 5)
                    }
                }
            }
        }
    }
}