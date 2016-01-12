import UIKit

//A payment driver is a generic interface for one payment processor
protocol AcceptOnUIMachinePaymentDriverDelegate: class {
    
    func transactionDidFailForDriver(driver: AnyObject, withMessage message: String)
    
    //Transaction has completed
    func transactionDidSucceedForDriver(driver: AnyObject, withChargeRes chargeRes: [String:AnyObject])
    
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
    
    //At this point, you should have filled out the nonceTokens and optionally 'email' properties.  The
    //'email' property is passed as part of the transaction and is used for credit-card transactions
    //only.  For some drivers that carry semantics like ApplePay, use the additional functions of
    //readyToCompleteTransactionDidFail and readyToCompleteTransactionDidSucceed to message the UI with any additional  information
    //it may need. In the case of ApplePay, that means calling apple pay's completion() handler inside
    //your overwritten readyToCompleteTransactionDidFail function
    func readyToCompleteTransaction(userInfo: Any?=nil) {
        if nonceTokens.count > 0 {
            let chargeInfo = AcceptOnAPIChargeInfo(cardTokens: self.nonceTokens, metadata: [:])
            
            self.delegate.api.chargeWithTransactionId(self.formOptions.token.id ?? "", andChargeinfo: chargeInfo) { chargeRes, err in
                if let err = err {
                    self.readyToCompleteTransactionDidFail(userInfo, withMessage: err.localizedDescription)
                    return
                }
                
                self.readyToCompleteTransactionDidSucceed(userInfo, withChargeRes: chargeRes!)
            }
        } else {
            self.readyToCompleteTransactionDidFail(userInfo, withMessage: "Could not connect to any payment processing services")
        }
        
    }
    
    //Override these functions to add behaviours to the AcceptOn API transaction stage
    ////////////////////////////////////////////////////////////////////////////////////
    func readyToCompleteTransactionDidFail(userInfo: Any?, withMessage message: String) {
        self.delegate.transactionDidFailForDriver(self, withMessage: message)
    }

    func readyToCompleteTransactionDidSucceed(userInfo: Any?, withChargeRes chargeRes: [String:AnyObject]) {
        self.delegate.transactionDidSucceedForDriver(self, withChargeRes: chargeRes)
    }
    ////////////////////////////////////////////////////////////////////////////////////
}