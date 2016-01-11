import UIKit

//A payment driver is a generic interface for one payment processor
protocol AcceptOnUIMachinePaymentDriverDelegate: class {
    
    func transactionDidFailForDriver(driver: AnyObject, withMessage message: String)
    
    //Transaction has completed
    func transactionDidSucceedForDriver(driver: AnyObject, withChargeRes chargeRes: [String:AnyObject])
    
    //Additional information may be necessary, you should show extra views at this time.  Returning
    //false here will cause the transaction to fail (e.g. should be 
    //return false if user hits back on additional information selector)
    func transactionDidFillOutUserInfoForDriver(driver: AnyObject, userInfo: AcceptOnUIMachineOptionalUserInfo, completion: (Bool, AcceptOnUIMachineUserInfo?)->())
    
    func transactionDidCancelForDriver(driver: AnyObject)
    
    var api: AcceptOnAPI { get }
}

class AcceptOnUIMachinePaymentDriver: NSObject {
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    weak var delegate: AcceptOnUIMachinePaymentDriverDelegate!
    
    var name: String {
        return "<unnamed>"
    }
    
    //Tokens that were retrieved from the drivers
    var nonceTokens: [String] = []
    
    //-----------------------------------------------------------------------------------------------------
    //Constructors
    //-----------------------------------------------------------------------------------------------------
    var formOptions: AcceptOnUIMachineFormOptions!
    required init(formOptions: AcceptOnUIMachineFormOptions) {
        self.formOptions = formOptions
    }
    
    func beginTransaction() {
    }
    
    //At this point, you should have filled out the nonceTokens
    func readyToCompleteTransaction() {
        if nonceTokens.count > 0 {
            //Request any last needed information
            self.delegate.transactionDidFillOutUserInfoForDriver(self, userInfo: self.formOptions.userInfo!, completion: { (didComplete, userInfo) -> () in
                if didComplete {
                    //Pass through metadata if necessary
                    userInfo!.metadata = self.formOptions.userInfo!.metadata
                    var output = userInfo!.toDictionary()
                    
                    let chargeInfo = AcceptOnAPIChargeInfo(cardTokens: self.nonceTokens, metadata: userInfo!.toDictionary())
                    
                    self.delegate.api.chargeWithTransactionId(self.formOptions.token.id ?? "", andChargeinfo: chargeInfo) { chargeRes, err in
                        if let err = err {
                            self.delegate.transactionDidFailForDriver(self, withMessage: err.localizedDescription)
                            return
                        }
                        
                        self.delegate.transactionDidSucceedForDriver(self, withChargeRes: chargeRes!)
                    }
                } else {
                    self.delegate.transactionDidCancelForDriver(self)
                }
            })
        } else {
            self.delegate.transactionDidFailForDriver(self, withMessage: "Could not connect to any payment processing services")
        }
        
    }
}