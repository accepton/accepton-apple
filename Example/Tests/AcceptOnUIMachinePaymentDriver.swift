//// https://github.com/Quick/Quick
//
//import Quick
//import Nimble
//import accepton
//
//class AcceptOnUIMachinePaymentDriverDelegateStub: AcceptOnUIMachinePaymentDriverDelegate {
//    func transactionDidFailForDriver(driver: AcceptOnUIMachinePaymentDriver, withMessage message: String) {
//        
//    }
//    
//    //Transaction has completed
//    func transactionDidSucceedForDriver(driver: AcceptOnUIMachinePaymentDriver, withChargeRes chargeRes: [String:AnyObject]){
//        
//    }
//    
//    func transactionDidCancelForDriver(driver: AcceptOnUIMachinePaymentDriver){
//        
//    }
//    
//    let api: AcceptOnAPI
//    init(api: AcceptOnAPI) {
//        self.api = api
//    }
//}
//
//class AcceptOnUIMachinePaymentDriverSpec: QuickSpec {
//    override func spec() {
//        AcceptOnAPIFactory.query.withAtleast(.Sandbox).each { apiInfo, desc in
//            context(desc) {
//                var paymentDelegate: AcceptOnUIMachinePaymentDriverDelegateStub {
//                    return AcceptOnUIMachinePaymentDriverDelegateStub(api: apiInfo.api)
//                }
//                
//                context("Stripe") {
//                    var stripePaymentDriver: AcceptOnUIMachinePaymentDriver {
//                        return 
//                    }
//                }
//            }
//        }
//    }
//}