import PassKit
import UIKit
import Stripe

@objc protocol AcceptOnUIMachineCreditCardDriverDelegate {
    optional func creditCardTransactionDidFailWithMessage(message: String)
    optional func creditCardTransactionDidSucceedWithChargeRes(chargeRes: [String:AnyObject])
    optional func creditCardTransactionDidCancel()
}

//Generic credit-card driver interface
@objc class AcceptOnUIMachineCreditCardDriver: NSObject {
    weak var delegate: AcceptOnUIMachineCreditCardDriverDelegate?
    
    var formOptions: AcceptOnUIMachineFormOptions!
    func beginCreditCardTransactionRequestWithFormOptions(formOptions: AcceptOnUIMachineFormOptions) {
        self.formOptions = formOptions
    }
}