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
        
        //If we have a stripe payment processor available in the options
        if self.formOptions.paymentMethods.supportsStripe {
            //Set the stripe publishable key
            guard let stripePublishableKey = formOptions.paymentMethods.stripePublishableKey else {
                puts("AcceptOnUIMachineApplePayDriver: Error, could not complete ApplePay transaction, Stripe was enabled but there was no publishable key")
                completion(PKPaymentAuthorizationStatus.Failure)
                return
            }
            Stripe.setDefaultPublishableKey(stripePublishableKey)
            
            //Attempt to create a transaction with Stripe with the retrieved ApplePay token
            STPAPIClient.sharedClient().createTokenWithPayment(payment) { (token, err) -> Void in
                //Stripe transaction failed, do not continue
                if let err = err {
                    puts("AcceptOnUIMachineApplePayDriver: Error, could not complete transaction after handing stripe a payment token: \(err.localizedDescription)")
                    completion(PKPaymentAuthorizationStatus.Failure)
                    return
                }
                
                //We received a stripe token, notify the AcceptOn servers
                let stripeTokenId = token!.tokenId
                let acceptOnTransactionToken = self.formOptions.token.id
                let chargeInfo = AcceptOnAPIChargeInfo(cardToken: stripeTokenId, email: "applepay@applepay.com")
                self.delegate?.api.chargeWithTransactionId(acceptOnTransactionToken, andChargeinfo: chargeInfo) { chargeRes, err in
                    if let err = err {
                        self.didErr = err
                        puts("AcceptOnUIMachineApplePayDriver: Error, could not complete transaction, failed to charge stripe token (forged from ApplePay) through to the accepton on servers: \(err.localizedDescription)")
                        completion(PKPaymentAuthorizationStatus.Failure)
                        return
                    }
                    
                    completion(PKPaymentAuthorizationStatus.Success)
                }
            }
        } else {
            puts("AcceptOnUIMachineApplePayDriver: Error, did retrieve ApplePay token, but there was no payment processor configured to accept ApplePay")
            completion(PKPaymentAuthorizationStatus.Failure)
        }
    }
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didSelectShippingAddress address: ABRecord, completion: (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void) {
        //Depreciated
    }
}