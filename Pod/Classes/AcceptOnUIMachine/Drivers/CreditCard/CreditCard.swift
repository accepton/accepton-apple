import PassKit
import UIKit
import Stripe

protocol AcceptOnUIMachineCreditCardDriverDelegate: class {
    func creditCardTransactionDidFailWithMessage(message: String)
    func creditCardTransactionDidSucceedWithChargeRes(chargeRes: [String:AnyObject])
    func creditCardTransactionDidCancel()
    
    var api: AcceptOnAPI { get }
}


//Generic credit-card driver interface
@objc class AcceptOnUIMachineCreditCardDriver: NSObject {
    weak var delegate: AcceptOnUIMachineCreditCardDriverDelegate!
    
    var formOptions: AcceptOnUIMachineFormOptions!
    var creditCardParams: AcceptOnUIMachineCreditCardParams!
    func beginCreditCardTransactionRequestWithFormOptions(formOptions: AcceptOnUIMachineFormOptions, andCreditCardParams creditCardParams: AcceptOnUIMachineCreditCardParams) {
        self.formOptions = formOptions
        self.creditCardParams = creditCardParams
        
        //We don't want this to execute on the same thread of execution in-case
        //we fail right away. This would cause multiple messages to be dispatched
        //within the same frame of execution and the UI could glitch out (e.g.
        //client may get a hide/show request in the same frame of executuion)
        dispatch_async(dispatch_get_main_queue()) {
            self.startCreditCardTransaction()
        }
    }
    
    func startCreditCardTransaction() {
        //Override this function
    }
}