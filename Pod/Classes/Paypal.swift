import Foundation
import UIKit

@objc protocol AcceptOnUIMachinePaypalDriverDelegate {
    optional func paypalTransactionDidFailWithMessage(message: String)
    optional func paypalTransactionDidSucceed()
}

@objc class AcceptOnUIMachinePaypalDriver : NSObject, PayPalPaymentDelegate {
    weak var delegate: AcceptOnUIMachinePaypalDriverDelegate?
    
    //Present using the root view controller
    var presentingViewController: UIViewController! {
        get {
            let rvc = UIApplication.sharedApplication().windows.first?.rootViewController
            if rvc == nil {
                NSException(name:"AcceptOnUIMachinePaypalDriver", reason: "Tried to get the UIApplication.sharedApplication().windows.first.rootViewController to display the paypal view controller off of but this did not exist", userInfo: nil).raise()
            }
            
            return rvc
        }
        
    }
    
    func beginPaypalTransactionWithAmountInDollars(amount: String, andDescription: String) {
        PayPalMobile.initializeWithClientIdsForEnvironments([PayPalEnvironmentSandbox:"EAGEb2Sey28DzhMc4P0PNothBmsJggVKZK9kTBrw5bU_PP5tmRUSFSlPe62K56FGxF8LkmwA3vPn-LGh"])
        let _config = PayPalConfiguration()
        _config.acceptCreditCards = false
        _config.payPalShippingAddressOption = PayPalShippingAddressOption.PayPal
        
        let pp = PayPalPayment()
        pp.amount = 10
        pp.currencyCode = "USD"
        pp.shortDescription = "Widget"
        pp.intent = PayPalPaymentIntent.Sale
        pp.shippingAddress = PayPalShippingAddress(recipientName: "Test", withLine1: "test", withLine2: "test", withCity: "Tampa", withState: "Florida", withPostalCode: "33612", withCountryCode: "US")
        
        let ppvc = PayPalPaymentViewController(payment: pp, configuration: _config, delegate: self)
            presentingViewController?.presentViewController(ppvc, animated: true) { () -> Void in
        }
    }
    
    func payPalPaymentDidCancel(paymentViewController: PayPalPaymentViewController!) {
        
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController!, didCompletePayment completedPayment: PayPalPayment!) {
        
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController!, willCompletePayment completedPayment: PayPalPayment!, completionBlock: PayPalPaymentDelegateCompletionBlock!) {
        
    }
}