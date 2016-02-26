import UIKit

//A payment driver is a generic interface for one payment processor
public protocol AcceptOnUIMachinePaymentDriverDelegate: class {    
    func transactionDidFailForDriver(driver: AcceptOnUIMachinePaymentDriver, withMessage message: String)
    
    //Transaction has completed
    func transactionDidSucceedForDriver(driver: AcceptOnUIMachinePaymentDriver, withChargeRes chargeRes: [String:AnyObject])
    
    func transactionDidCancelForDriver(driver: AcceptOnUIMachinePaymentDriver)
    
    var api: AcceptOnAPI { get }
}

public class AcceptOnUIMachinePaymentDriver: NSObject {
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    public weak var delegate: AcceptOnUIMachinePaymentDriverDelegate!
    
    class var name: String {
        return "<unnamed>"
    }
    
    //Tokens that were retrieved from the drivers
    var nonceTokens: [String:AnyObject] = [:]
    
    var rawCreditCardInfo: AcceptOnAPICreditCardParams?
    
    //Email is only for credit-card forms
    var email: String?
    
    //Meta-data is passed through from formOptions
    var metadata: [String:AnyObject] {
        return self.formOptions.metadata
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Constructors
    //-----------------------------------------------------------------------------------------------------
    var formOptions: AcceptOnUIMachineFormOptions!
    public required init(formOptions: AcceptOnUIMachineFormOptions) {
        self.formOptions = formOptions
    }
    
    public func beginTransaction() {
    }
    
    //At this point, you should have filled out the nonceTokens, optionally the raw credit card information
    //and optionally 'email' properties.  The 'email' property is passed as part of the transaction and is 
    //used for credit-card transactions only.  For drivers that have more complex semantics, e.g. ApplePay, 
    //where you need to interleave actions within the transaction handshake, override the 
    //readyToCompleteTransactionDidFail and readyToCompleteTransactionDidSucceed to modify that behaviour.
    func readyToCompleteTransaction(userInfo: Any?=nil) {
        if nonceTokens.count > 0 {
            let chargeInfo = AcceptOnAPIChargeInfo(rawCardInfo: self.rawCreditCardInfo, cardTokens: self.nonceTokens, email: email, metadata: self.metadata)
            
            self.delegate.api.chargeWithTransactionId(self.formOptions.token.id, andChargeinfo: chargeInfo) { chargeRes, err in
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
    
    //Override these functions if you need to interleave actions in the transaction stage. E.g. Dismiss
    //a 3rd party UI or a 3-way handshake
    ////////////////////////////////////////////////////////////////////////////////////
    func readyToCompleteTransactionDidFail(userInfo: Any?, withMessage message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.transactionDidFailForDriver(self, withMessage: message)
        }
    }

    func readyToCompleteTransactionDidSucceed(userInfo: Any?, withChargeRes chargeRes: [String:AnyObject]) {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.transactionDidSucceedForDriver(self, withChargeRes: chargeRes)
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////
}
