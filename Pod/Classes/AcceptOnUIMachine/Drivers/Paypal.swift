import Foundation
import UIKit

@objc protocol AcceptOnUIMachinePaypalDriverDelegate {
    optional func paypalTransactionDidFailWithMessage(message: String)
    optional func paypalTransactionDidSucceedWithChargeRes(chargeRes: [String:AnyObject])
    optional func paypalTransactionDidCancel()
    
    var api: AcceptOnAPI { get }
}

@objc class AcceptOnUIMachinePaypalDriver : NSObject, PayPalPaymentDelegate {
    weak var delegate: AcceptOnUIMachinePaypalDriverDelegate?
    
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
    
    var chargeRes: [String:AnyObject]?
    var ppvc: PayPalPaymentViewController!
    var formOptions: AcceptOnUIMachineFormOptions!
    var didSucceed = false
    func beginPaypalTransactionWithFormOptions(formOptions: AcceptOnUIMachineFormOptions) {
        //TODO: retrieve key from accepton API
        PayPalMobile.initializeWithClientIdsForEnvironments([PayPalEnvironmentSandbox:"EAGEb2Sey28DzhMc4P0PNothBmsJggVKZK9kTBrw5bU_PP5tmRUSFSlPe62K56FGxF8LkmwA3vPn-LGh"])
        
        self.formOptions = formOptions
        self.chargeRes = nil
        self.didSucceed = false
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
        _presentingViewController.dismissViewControllerAnimated(true) { [weak self] in
            self?._presentingViewController.view.removeFromSuperview()
            self?._presentingViewController.removeFromParentViewController()
            self?._presentingViewController = nil
            self?.delegate?.paypalTransactionDidCancel?()
        }
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController!, didCompletePayment completedPayment: PayPalPayment!) {
        _presentingViewController.dismissViewControllerAnimated(true) { [weak self] in
            self?._presentingViewController.view.removeFromSuperview()
            self?._presentingViewController.removeFromParentViewController()
            self?._presentingViewController = nil
            
            if self?.didSucceed ?? false {
                
                assert(self?.chargeRes != nil)
                self?.delegate?.paypalTransactionDidSucceedWithChargeRes?(self?.chargeRes ?? [:])
            } else {
                self?.delegate?.paypalTransactionDidFailWithMessage?("Could not charge your PayPal account at this time")
            }
        }
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController!, willCompletePayment completedPayment: PayPalPayment!, completionBlock: PayPalPaymentDelegateCompletionBlock!) {
        let confirmation = completedPayment.confirmation
        
        //Parse response from paypal response
        if let responseType = confirmation["response_type"] as? String {
            if responseType == "payment" {
                let response = confirmation["response"] as! [String:AnyObject]
                let paypalTokenId = response["id"] as! String

                //Send it up to the AcceptOn servers
                let email = self.formOptions.userInfo?.emailAutofillHint ?? nil
                let chargeInfo = AcceptOnAPIChargeInfo(cardTokens: [paypalTokenId], metadata: ["email":email ?? ""])
                self.delegate?.api.chargeWithTransactionId(formOptions.token.id, andChargeinfo: chargeInfo) { chargeRes, err in
                    if let err = err {
                        puts("AcceptOnUIMachinePayPalDriver: Error, could not complete transaction, failed to charge paypal token through to the accepton on servers: \(err.localizedDescription)")
                        completionBlock()
                        return
                    }
        
                    self.didSucceed = true
                    self.chargeRes = chargeRes!
                    completionBlock()
                }
            }
            
            return
        }
        
        //Failed payment, do not set didSucceed
        completionBlock()
    }
}
