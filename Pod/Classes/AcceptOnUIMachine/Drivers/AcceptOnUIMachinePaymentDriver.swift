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
    
    //-----------------------------------------------------------------------------------------------------
    //Constructors
    //-----------------------------------------------------------------------------------------------------
    func beginTransactionWithFormOptions(formOptions: AcceptOnUIMachineFormOptions) {
        //Should allowed to be called multiple times
    }
}