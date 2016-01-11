import Foundation
import Stripe

extension STPCardParams {
    convenience init(_ creditCardParams: AcceptOnUIMachineCreditCardParams) {
        self.init()
        self.number = creditCardParams.number
        self.expMonth = UInt(((creditCardParams.expMonth ?? "") as NSString).intValue)
        self.expYear = UInt((creditCardParams.expYear as NSString).intValue)
        self.cvc = creditCardParams.cvc
    }
}


class AcceptOnUIMachineCreditCardStripePlugin: AcceptOnUIMachineCreditCardDriverPlugin {
    override func beginTransactionWithFormOptions(formOptions: AcceptOnUIMachineFormOptions) {
        //Assuming they are using stripe
        let stripePublishableKey = formOptions.paymentMethods.stripePublishableKey
        if let stripePublishableKey = stripePublishableKey {
            Stripe.setDefaultPublishableKey(stripePublishableKey)
            let card = STPCardParams(formOptions.creditCardParams!)
            STPAPIClient.sharedClient().createTokenWithCard(card) { token, err in
                if let err = err {
                    self.delegate.creditCardPlugin(self, didFailWithMessage: err.localizedDescription)
                    return
                }
                
                let tokenId = token!.tokenId
                self.delegate.creditCardPlugin(self, didSucceedWithNonce: tokenId)
            }
        } else {
            self.delegate.creditCardPlugin(self, didFailWithMessage: "Stripe could not be configured")
        }
    }
}