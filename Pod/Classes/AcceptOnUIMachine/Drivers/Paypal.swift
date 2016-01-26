import Foundation
import UIKit
import PaypalPrivate

@objc class AcceptOnUIMachinePayPalDriver : AcceptOnUIMachinePaymentDriver, PayPalPaymentDelegate {
    //Present using a specially created view controller applied to the root window
    var _presentingViewController: UIViewController!
    var presentingViewController: UIViewController! {
        get {
            if (_presentingViewController == nil) {
                _presentingViewController = UIViewController()
                
                let rv = UIApplication.sharedApplication().windows.first
                if rv == nil {
                    NSException(name:"AcceptOnUIMachinePaypalDriver", reason: "Tried to get the UIApplication.sharedApplication().windows.first to display the paypal view controller off of but this did not exist", userInfo: nil).raise()
                }
                
                rv!.addSubview(_presentingViewController.view)
                _presentingViewController.view.bounds = UIScreen.mainScreen().bounds
            }
            
            return _presentingViewController
        }
    }
    
    override class var name: String {
        return "paypal"
    }
    var ppvc: PayPalPaymentViewController!
    
    enum State {
        case NotStarted                                       //Initialized
        case WaitingForPaypalToSendToken                      //Showing the PayPal form, user entering info or it's transacting
        case CompletingTransactionWithAccepton                //Now we are completing the transaction with accepton
        case TransactionWithAcceptonDidFail                   //stateInfo is the error message
        case TransactionWithAcceptonDidSucceed                //stateInfo is the charge information
        case UIDidFinish
    }
    var state: State = .NotStarted {
        didSet {
            stateInfo = nil
        }
    }
    var stateInfo: Any?
    
    override func beginTransaction() {
        self.state = .WaitingForPaypalToSendToken
        //TODO: retrieve key from accepton API
        
        if delegate.api.isProduction {
            PayPalMobile.initializeWithClientIdsForEnvironments([PayPalEnvironmentProduction:self.formOptions.paymentMethods.paypalRestClientId!])
            PayPalMobile.preconnectWithEnvironment(PayPalEnvironmentProduction)
        } else {
            PayPalMobile.initializeWithClientIdsForEnvironments([PayPalEnvironmentSandbox:self.formOptions.paymentMethods.paypalRestClientId!])
            PayPalMobile.preconnectWithEnvironment(PayPalEnvironmentSandbox)
        }
        
        let _config = PayPalConfiguration()
        _config.acceptCreditCards = false
        _config.payPalShippingAddressOption = PayPalShippingAddressOption.None
        
        let pp = PayPalPayment()
        pp.amount = NSDecimalNumber(double: Double(formOptions.amountInCents) / 100.0)
        pp.currencyCode = "USD"
        pp.shortDescription = formOptions.itemDescription
        pp.intent = PayPalPaymentIntent.Sale
        
        ppvc = PayPalPaymentViewController(payment: pp, configuration: _config, delegate: self)
        presentingViewController.presentViewController(ppvc, animated: true, completion: nil)
    }
    
    func payPalPaymentDidCancel(paymentViewController: PayPalPaymentViewController!) {
        handlePaypalUICompletion()
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController!, didCompletePayment completedPayment: PayPalPayment!) {
        handlePaypalUICompletion()
    }
    
    //We don't necessarily care whether PayPal thinks it completed or failed.  We rely on the AcceptOn transaction
    //state
    func handlePaypalUICompletion() {
        if self.state == .UIDidFinish { return }
        
        switch self.state {
        case .TransactionWithAcceptonDidSucceed:
            self.delegate.transactionDidSucceedForDriver(self, withChargeRes: stateInfo as! [String:AnyObject])
        case .TransactionWithAcceptonDidFail:
            self.delegate.transactionDidFailForDriver(self, withMessage: stateInfo as! String)
        case .WaitingForPaypalToSendToken:
            self.delegate.transactionDidCancelForDriver(self)
        case .CompletingTransactionWithAccepton:
            //Do not allow the UI to close at this point, we can't stop the transaction
            return
        default:
            return
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.state = .UIDidFinish
            self._presentingViewController.dismissViewControllerAnimated(true) { [weak self] in
                self?._presentingViewController.view.removeFromSuperview()
                self?._presentingViewController.removeFromParentViewController()
                self?._presentingViewController = nil
            }
        }
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController!, willCompletePayment completedPayment: PayPalPayment!, completionBlock: PayPalPaymentDelegateCompletionBlock!) {
        dispatch_async(dispatch_get_main_queue()) {
            if self.state != .WaitingForPaypalToSendToken { return }
            let confirmation = completedPayment.confirmation
            
            //Parse response from paypal response
            guard let responseType = confirmation["response_type"] as? String else {
                self.delegate.transactionDidFailForDriver(self, withMessage: "Could not get response_type from confirmation")
                return
            }
            
            guard responseType == "payment" else {
                self.delegate.transactionDidFailForDriver(self, withMessage: "Response type from PayPal was not a payment")
                return
            }
            
            guard let response = confirmation["response"] as? [String:AnyObject] else {
                self.delegate.transactionDidFailForDriver(self, withMessage: "Could not decode response from paypal's confirmation")
                return
            }
            guard let tokenId = response["id"] as? String else {
                self.delegate.transactionDidFailForDriver(self, withMessage: "Could not decode token id from paypal's response")
                return
            }
            self.nonceTokens = ["paypal_payment_id": tokenId]
            
            self.state = .CompletingTransactionWithAccepton
            self.readyToCompleteTransaction(completionBlock)
        }
    }
    
    //Currently, PayPal verifies using a different endpoint then the rest of the tokenizers
    override func readyToCompleteTransaction(userInfo: Any?=nil) {
        if nonceTokens.count > 0 {
            let chargeInfo = AcceptOnAPIChargeInfo(cardTokens: self.nonceTokens, email: email, metadata: self.metadata)
            
            self.delegate.api.verifyPaypalWithTransactionId(self.formOptions.token.id, andChargeInfo: chargeInfo) { chargeRes, err in
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
    
    override func readyToCompleteTransactionDidFail(userInfo: Any?, withMessage message: String) {
        self.state = .TransactionWithAcceptonDidFail
        self.stateInfo = "Could not complete the payment at this time"
        let completion = userInfo as! PayPalPaymentDelegateCompletionBlock
        completion()
    }
    
    override func readyToCompleteTransactionDidSucceed(userInfo: Any?, withChargeRes chargeRes: [String : AnyObject]) {
        self.state = .TransactionWithAcceptonDidSucceed
        self.stateInfo = chargeRes
        
        let completion = userInfo as! PayPalPaymentDelegateCompletionBlock
        completion()
    }
}
