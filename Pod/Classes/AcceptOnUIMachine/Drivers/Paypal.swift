import Foundation
import UIKit

@objc protocol AcceptOnUIMachinePaypalDriverDelegate {
    optional func paypalTransactionDidFailWithMessage(message: String)
    optional func paypalTransactionDidSucceed()
    optional func paypalTransactionDidCancel()
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
    
    var ppvc: PayPalPaymentViewController!
    func beginPaypalTransactionWithAmountInCents(amountInCents: NSDecimalNumber, andDescription description: String) {
        PayPalMobile.initializeWithClientIdsForEnvironments([PayPalEnvironmentSandbox:"EAGEb2Sey28DzhMc4P0PNothBmsJggVKZK9kTBrw5bU_PP5tmRUSFSlPe62K56FGxF8LkmwA3vPn-LGh"])
        let _config = PayPalConfiguration()
        _config.acceptCreditCards = false
        _config.payPalShippingAddressOption = PayPalShippingAddressOption.PayPal
        
        let pp = PayPalPayment()
        pp.amount = NSDecimalNumber(double: amountInCents.doubleValue / 100.0)
        pp.currencyCode = "USD"
        pp.shortDescription = description
        pp.intent = PayPalPaymentIntent.Sale
        pp.shippingAddress = PayPalShippingAddress(recipientName: "Test", withLine1: "test", withLine2: "test", withCity: "Tampa", withState: "Florida", withPostalCode: "33612", withCountryCode: "US")
        
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
            
            self?.delegate?.paypalTransactionDidSucceed?()
        }
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController!, willCompletePayment completedPayment: PayPalPayment!, completionBlock: PayPalPaymentDelegateCompletionBlock!) {
        let confirmation = completedPayment.confirmation
        
        completionBlock()
    }
}