import Foundation
import UIKit

@objc protocol AcceptOnUIMachinePaypalDriverDelegate {
    optional func paypalTransactionDidFailWithMessage(message: String)
    optional func paypalTransactionDidSucceed()
}

@objc public class AcceptOnUIMachinePaypalDriver : NSObject, PayPalPaymentDelegate {
    weak var delegate: AcceptOnUIMachinePaypalDriverDelegate?
    
    //Present using the root view controller
    var presentingViewController: UIViewController!
    
    var ppvc: UIViewController?
    func beginPaypalTransactionWithAmountInDollars(amount: Int, andDescription: String) {
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
        
        ppvc = PayPalPaymentViewController(payment: pp, configuration: _config, delegate: self)
        presentingViewController?.view.addSubview(ppvc!.view)
        presentingViewController?.view.bringSubviewToFront(ppvc!.view)
        ppvc!.view.bounds = CGRectMake(0, 0, 100, 100)
    }
    
    public func payPalPaymentDidCancel(paymentViewController: PayPalPaymentViewController!) {
        
    }
    
    public func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController!, didCompletePayment completedPayment: PayPalPayment!) {
        
    }
    
    public func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController!, willCompletePayment completedPayment: PayPalPayment!, completionBlock: PayPalPaymentDelegateCompletionBlock!) {
        
    }
}