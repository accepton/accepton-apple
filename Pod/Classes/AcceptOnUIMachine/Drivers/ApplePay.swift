import PassKit
import UIKit
import Stripe

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
    
    override class var name: String {
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
    
    enum State {
        case NotStarted                                       //Initialized
        case WaitingForApplePayToSendNonce                    //Showing the ApplePay form, user entering info or it's transacting
        case WaitingForPaymentProcessorNonceFromApplePayNonce //Waiting for stripe, etc. to respond
        case CompletingTransactionWithAccepton                //Now we are completing the transaction with accepton
        case TransactionWithAcceptonDidFail                   //stateInfo is the error message
        case TransactionWithAcceptonDidSucceed                //stateInfo is the charge information
        case UIDidFinish                                      //UI did close (failure or completion)
    }
    var state: State = .NotStarted {
        didSet {
            stateInfo = nil
        }
    }
    var stateInfo: Any?
    
    override func beginTransaction() {
        state = .WaitingForApplePayToSendNonce
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
        
        presentingViewController.presentViewController(pkvc, animated: true, completion: nil)
    }
    
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        if state == .UIDidFinish { return }
        dispatch_async(dispatch_get_main_queue()) {
            switch self.state {
            //User hit 'cancel' on ApplePay because we never got a nonce back from it
            case .WaitingForApplePayToSendNonce:
                fallthrough
            case .WaitingForPaymentProcessorNonceFromApplePayNonce:
                self.delegate.transactionDidCancelForDriver(self)
            case .TransactionWithAcceptonDidFail:
                self.delegate.transactionDidFailForDriver(self, withMessage: self.stateInfo as! String)
            case .TransactionWithAcceptonDidSucceed:
                self.delegate.transactionDidSucceedForDriver(self, withChargeRes: self.stateInfo as! [String:AnyObject])
            default:
                break
            }
            
            self.state = .UIDidFinish
            
            self.pkvc.dismissViewControllerAnimated(true) {
                self._presentingViewController.view.removeFromSuperview()
                self._presentingViewController.removeFromParentViewController()
                self._presentingViewController = nil
            }
        }
    }
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: (PKPaymentAuthorizationStatus) -> Void) {
        if state != .WaitingForApplePayToSendNonce { return }
        state = .WaitingForPaymentProcessorNonceFromApplePayNonce
        //If we have a stripe payment processor available in the options
        if self.formOptions.paymentMethods.supportsStripe {
            //Set the stripe publishable key
            guard let stripePublishableKey = self.formOptions.paymentMethods.stripePublishableKey else {
                self.delegate.transactionDidFailForDriver(self, withMessage: "AcceptOnUIMachineApplePayDriver: Error, could not complete ApplePay transaction, Stripe was enabled but there was no publishable key")
                completion(PKPaymentAuthorizationStatus.Failure)
                return
            }
            Stripe.setDefaultPublishableKey(stripePublishableKey)
            
            //Attempt to create a transaction with Stripe with the retrieved ApplePay token
            STPAPIClient.sharedClient().createTokenWithPayment(payment) { (token, err) -> Void in
                if self.state != .WaitingForPaymentProcessorNonceFromApplePayNonce { return }
                self.state = .CompletingTransactionWithAccepton
                
                //Stripe transaction failed, do not continue
                if let err = err {
                    self.delegate.transactionDidFailForDriver(self, withMessage: "Could not complete transaction after handing stripe a payment token: \(err.localizedDescription)")
                    completion(PKPaymentAuthorizationStatus.Failure)
                    return
                }
                
                //We received a stripe token, notify the AcceptOn servers
                let stripeTokenId = token!.tokenId
                
                self.nonceTokens = ["stripe":stripeTokenId]
                self.readyToCompleteTransaction(completion)
            }
        } else {
            self.delegate.transactionDidFailForDriver(self, withMessage: "No payment processors found that support ApplePay")
            completion(PKPaymentAuthorizationStatus.Failure)
        }
    }
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didSelectShippingAddress address: ABRecord, completion: (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void) {
        //Depreciated
    }
    
    override func readyToCompleteTransactionDidFail(userInfo: Any?, withMessage message: String) {
        self.state = .TransactionWithAcceptonDidFail
        self.stateInfo = "Could not complete the payment at this time"
        let completion = userInfo as! ((PKPaymentAuthorizationStatus) -> Void)
        completion(PKPaymentAuthorizationStatus.Failure)
    }
    
    override func readyToCompleteTransactionDidSucceed(userInfo: Any?, withChargeRes chargeRes: [String : AnyObject]) {
        self.state = .TransactionWithAcceptonDidSucceed
        self.stateInfo = chargeRes
        
        let completion = userInfo as! ((PKPaymentAuthorizationStatus) -> Void)
        completion(PKPaymentAuthorizationStatus.Success)
    }
}
