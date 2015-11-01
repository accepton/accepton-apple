import PassKit
import UIKit

@objc protocol AcceptOnUIMachineApplePayDriverDelegate {
    optional func applePayTransactionDidFailWithMessage(message: String)
    optional func applePayTransactionDidSucceed()
    optional func applePayTransactionDidCancel()
}

enum AcceptOnUIMachineApplePayDriverAvailability {
    case NotSupported  //Not supported (parental controls, etc).
    case NeedToSetup   //User has no cards setup
    case Ready         //User has a card setup
}

extension AcceptOnUIMachineFormOptions {
}

@objc class AcceptOnUIMachineApplePayDriver: NSObject, PKPaymentAuthorizationViewControllerDelegate {
    class func checkAvailability() -> AcceptOnUIMachineApplePayDriverAvailability {
        let enabled = PKPaymentAuthorizationViewController.canMakePayments()
        if (!enabled) { return .NotSupported }
        
        if #available(iOS 9, *) {
            if (PKPaymentAuthorizationViewController.canMakePaymentsUsingNetworks([PKPaymentNetworkAmex, PKPaymentNetworkDiscover, PKPaymentNetworkVisa, PKPaymentNetworkMasterCard])) {
                return .Ready
            }
        } else {
            if (PKPaymentAuthorizationViewController.canMakePaymentsUsingNetworks([PKPaymentNetworkAmex, PKPaymentNetworkVisa, PKPaymentNetworkMasterCard])) {
                return .Ready
            }
         }
        
        return .NeedToSetup
    }
    
    weak var delegate: AcceptOnUIMachineApplePayDriverDelegate?
    
    //Present using a specially created view controller applied to the root window
    var _presentingViewController: UIViewController!
    var presentingViewController: UIViewController! {
        get {
            if (_presentingViewController == nil) {
                _presentingViewController = UIViewController()
                
                let rv = UIApplication.sharedApplication().windows.first
                if rv == nil {
                    NSException(name:"AcceptOnUIMachineApplePayDriver", reason: "Tried to get the UIApplication.sharedApplication().windows.first to display the paypal view controller off of but this did not exist", userInfo: nil).raise()
                }
                
                rv!.addSubview(_presentingViewController.view)
                _presentingViewController.view.bounds = UIScreen.mainScreen().bounds
            }
            
            return _presentingViewController
        }
    }
    
    var pkvc: PKPaymentAuthorizationViewController!
    func beginApplePayTransactionForPaymentRequest(request: PKPaymentRequest) {
        pkvc = PKPaymentAuthorizationViewController(paymentRequest: request)
        pkvc.delegate = self
        didHitCancel = true
        if (pkvc == nil) {
            self.delegate?.applePayTransactionDidFailWithMessage?("Could not load ApplePay at this time")
            return
        }
        
        presentingViewController.presentViewController(pkvc, animated: true, completion: nil)
    }
    
    var didHitCancel = true
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        pkvc.dismissViewControllerAnimated(true) { [weak self] in
            self?._presentingViewController.view.removeFromSuperview()
            self?._presentingViewController.removeFromParentViewController()
            self?._presentingViewController = nil
            
            if (self!.didHitCancel) {
                self?.delegate?.applePayTransactionDidCancel?()
            } else {
                self?.delegate?.applePayTransactionDidSucceed?()
            }
        }
    }
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: (PKPaymentAuthorizationStatus) -> Void) {
        didHitCancel = false
        
        //Send this off to the AcceptOn servers to verify before returning success
        let paymentToken = payment.token
        puts("\(paymentToken)")
        
        completion(PKPaymentAuthorizationStatus.Success)
    }
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didSelectShippingAddress address: ABRecord, completion: (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void) {
        
    }
}