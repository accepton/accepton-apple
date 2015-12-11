import PassKit
import UIKit
import Stripe

@objc protocol AcceptOnUIMachineApplePayDriverDelegate {
    optional func applePayTransactionDidFailWithMessage(message: String)
    optional func applePayTransactionDidSucceedWithChargeRes(chargeRes: [String:AnyObject])
    optional func applePayTransactionDidCancel()
    
    var api: AcceptOnAPI { get }
}

enum AcceptOnUIMachineApplePayDriverAvailability {
    case NotSupported  //Not supported (parental controls, etc).
    case NeedToSetup   //User has no cards setup
    case Ready         //User has a card setup
}

extension AcceptOnUIMachineFormOptions {
    func createApplePayPaymentRequest() -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.currencyCode = "USD"
        request.countryCode = "US"
        request.merchantIdentifier = "merchant.com.accepton"
        
        let total = NSDecimalNumber(mantissa: UInt64(amountInCents), exponent: -2, isNegative: false)
        let totalSummary = PKPaymentSummaryItem(label: "Total", amount: total)
        
        request.paymentSummaryItems = [totalSummary]
        
        if #available(iOS 9, *) {
            request.supportedNetworks = [PKPaymentNetworkAmex, PKPaymentNetworkDiscover, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa]
            request.merchantCapabilities = [PKMerchantCapability.Capability3DS, PKMerchantCapability.CapabilityCredit, PKMerchantCapability.CapabilityDebit]
        } else {
            request.supportedNetworks = [PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa]
            request.merchantCapabilities = [PKMerchantCapability.Capability3DS]
        }
        
        return request
    }
}

@objc class AcceptOnUIMachineApplePayDriver: AcceptOnUIMachinePaymentDriver, PKPaymentAuthorizationViewControllerDelegate {
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
    
    override var name: String {
        return "apple_pay"
    }
    
    
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
    var shouldComplete: Bool!
    var chargeRes: [String:AnyObject]?
    override func beginTransactionWithFormOptions(formOptions: AcceptOnUIMachineFormOptions) {
        self.formOptions = formOptions
        didErr = nil
        chargeRes = nil
        
        //Allow the transaction to complete, if the user hits cancel, the multi-stage transaction
        //will not complete without the user's permission
        self.shouldComplete = true
        
        let availability = AcceptOnUIMachineApplePayDriver.checkAvailability()
        if (availability == .NotSupported) {
            self.delegate.transactionDidFailForDriver(self, withMessage: "Your device does not support ApplePay")
            return
        } else if (availability == AcceptOnUIMachineApplePayDriverAvailability.NeedToSetup) {
            self.delegate.transactionDidFailForDriver(self, withMessage: "You need to setup ApplePay")
            PKPassLibrary().openPaymentSetup()
            return
        }
        
        pkvc = PKPaymentAuthorizationViewController(paymentRequest: formOptions.createApplePayPaymentRequest())
        if (pkvc == nil) {
            self.delegate.transactionDidFailForDriver(self, withMessage: "Could not load ApplePay")
            return
        }
        pkvc.delegate = self
        didHitCancel = true
        
        presentingViewController.presentViewController(pkvc, animated: true, completion: nil)
    }
    
    var didHitCancel = true
    var didErr: NSError?  //Used to check stripe successful-ness in processing the token
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        //Disable the rest of the transaction stages.  This handler is called when both
        //the ApplePay cancel button is clicked or the transaction completes
        self.shouldComplete = false
        
        pkvc.dismissViewControllerAnimated(true) { [weak self] in
            self?._presentingViewController.view.removeFromSuperview()
            self?._presentingViewController.removeFromParentViewController()
            self?._presentingViewController = nil
            
            if (self?.didHitCancel ?? false) {
                self?.delegate.transactionDidCancelForDriver(self!)
            } else {
                //Did payment-processor process the payment token?
                if (self!.didErr != nil) {
                    self?.delegate?.transactionDidFailForDriver(self!, withMessage:"Could not connect to the payment servers. Please try a different payment method.")
                } else {
                    if let chargeRes = self?.chargeRes {
                        self?.delegate?.transactionDidSucceedForDriver(self!, withChargeRes: chargeRes)
                    } else {
                        self?.delegate?.transactionDidFailForDriver(self!, withMessage:"The payment servers will not process charges at this time. Please try a different payment method.")
                    }
                }
            }
        }
    }
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: (PKPaymentAuthorizationStatus) -> Void) {
        let userInfo = self.formOptions.userInfo ?? AcceptOnUIMachineOptionalUserInfo()
        self.delegate.transactionDidFillOutUserInfoForDriver(self, userInfo: userInfo) { success, userInfo in
            //User may have hit back when filling out extra information, abort
            if !success {
                self.didHitCancel = true
                completion(PKPaymentAuthorizationStatus.Failure)
                return
            }
            
            //If we have a stripe payment processor available in the options
            if self.formOptions.paymentMethods.supportsStripe {
                //Set the stripe publishable key
                guard let stripePublishableKey = self.formOptions.paymentMethods.stripePublishableKey else {
                    puts("AcceptOnUIMachineApplePayDriver: Error, could not complete ApplePay transaction, Stripe was enabled but there was no publishable key")
                    self.didHitCancel = false
                    completion(PKPaymentAuthorizationStatus.Failure)
                    return
                }
                Stripe.setDefaultPublishableKey(stripePublishableKey)
                
                //Attempt to create a transaction with Stripe with the retrieved ApplePay token
                STPAPIClient.sharedClient().createTokenWithPayment(payment) { (token, err) -> Void in
                    if self.shouldComplete == false { return }
                    //Stripe transaction failed, do not continue
                    if let err = err {
                        puts("AcceptOnUIMachineApplePayDriver: Error, could not complete transaction after handing stripe a payment token: \(err.localizedDescription)")
                        self.didHitCancel = false
                        completion(PKPaymentAuthorizationStatus.Failure)
                        return
                    }
                    
                    //We received a stripe token, notify the AcceptOn servers
                    let stripeTokenId = token!.tokenId
                    let acceptOnTransactionToken = self.formOptions.token.id
                    
                    //If there was an email provided in the optional user information on the UIMachine creation, then
                    //pass this along.  Else, pass along nil.
                    let email = self.formOptions.userInfo?.emailAutofillHint ?? nil
                    let chargeInfo = AcceptOnAPIChargeInfo(cardToken: stripeTokenId, email: email)
                    self.delegate?.api.chargeWithTransactionId(acceptOnTransactionToken, andChargeinfo: chargeInfo) { chargeRes, err in
                        if self.shouldComplete == false { return }
                        if let err = err {
                            self.didErr = err
                            puts("AcceptOnUIMachineApplePayDriver: Error, could not complete transaction, failed to charge stripe token (forged from ApplePay) through to the accepton on servers: \(err.localizedDescription)")
                            self.didHitCancel = false
                            completion(PKPaymentAuthorizationStatus.Failure)
                            return
                        }
                        
                        self.didHitCancel = false
                        
                        self.chargeRes = chargeRes!
                        completion(PKPaymentAuthorizationStatus.Success)
                    }
                }
            } else {
                puts("AcceptOnUIMachineApplePayDriver: Error, did retrieve ApplePay token, but there was no payment processor configured to accept ApplePay")
                completion(PKPaymentAuthorizationStatus.Failure)
            }
        }
    }
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didSelectShippingAddress address: ABRecord, completion: (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void) {
        //Depreciated
    }
}
