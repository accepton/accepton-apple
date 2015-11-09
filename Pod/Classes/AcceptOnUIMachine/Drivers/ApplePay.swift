import PassKit
import UIKit
import Stripe

@objc protocol AcceptOnUIMachineApplePayDriverDelegate {
    optional func applePayTransactionDidFailWithMessage(message: String)
    optional func applePayTransactionDidSucceed()
    optional func applePayTransactionDidCancel()
    
    var api: AcceptOnAPI { get }
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
    var formOptions: AcceptOnUIMachineFormOptions!
    func beginApplePayTransactionForPaymentRequest(request: PKPaymentRequest, withFormOptions formOptions: AcceptOnUIMachineFormOptions) {
        self.formOptions = formOptions
        
        didErr = nil
        let availability = AcceptOnUIMachineApplePayDriver.checkAvailability()
        if (availability == .NotSupported) {
            self.delegate?.applePayTransactionDidFailWithMessage?("Your device does not support ApplePay")
            return
        } else if (availability == AcceptOnUIMachineApplePayDriverAvailability.NeedToSetup) {
            self.delegate?.applePayTransactionDidFailWithMessage?("You need to set up ApplePay")
            PKPassLibrary().openPaymentSetup()
            return
        }
        
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
    var didErr: NSError?  //Used to check stripe successful-ness in processing the token
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        pkvc.dismissViewControllerAnimated(true) { [weak self] in
            self?._presentingViewController.view.removeFromSuperview()
            self?._presentingViewController.removeFromParentViewController()
            self?._presentingViewController = nil
            
            if (self!.didHitCancel) {
                self?.delegate?.applePayTransactionDidCancel?()
            } else {
                //Did payment-processor process the payment token?
                if (self!.didErr != nil) {
                    self?.delegate?.applePayTransactionDidFailWithMessage?("Could not connect to the payment servers. Please try again later.")
                } else {
                    self?.delegate?.applePayTransactionDidSucceed?()
                }
            }
        }
    }
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: (PKPaymentAuthorizationStatus) -> Void) {
        didHitCancel = false
        
        if self.formOptions.paymentMethods.supportsStripe {
            guard let stripePublishableKey = formOptions.paymentMethods.stripePublishableKey else {
                puts("Stripe was enabled but there was no publishable key")
                completion(PKPaymentAuthorizationStatus.Failure)
                return
            }
            
            //Attempt to create a transaction with Stripe with the ApplePay token
            Stripe.setDefaultPublishableKey(stripePublishableKey)
            STPAPIClient.sharedClient().createTokenWithPayment(payment) { (token, err) -> Void in
                if err != nil {
                    puts("Stripe returned an error: \(err)")
                    completion(PKPaymentAuthorizationStatus.Failure)
                    return
                }
                
                //Now we talk to accepton-on servers to complete the transaction
                let tokenId = token!.tokenId
                let chargeInfo = AcceptOnAPIChargeInfo(cardToken: tokenId, email: "applepay@applepay.com")
                self.delegate?.api.chargeWithTransactionId(self.formOptions.token!.id ?? "", andChargeinfo: chargeInfo) { chargeRes, err in
                    if let err = err {
                        self.didErr = err
                        puts("AcceptOn failed to charge: \(err)")
                        completion(PKPaymentAuthorizationStatus.Failure)
                        return
                    }
                    
                    completion(PKPaymentAuthorizationStatus.Success)
                }
            }
        } else {
            puts("No payment processor configured that supports apple-pay")
            completion(PKPaymentAuthorizationStatus.Failure)
        }
    }
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didSelectShippingAddress address: ABRecord, completion: (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void) {
        //Depreciated
    }
}