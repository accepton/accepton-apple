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

class AcceptOnUIMachineCreditCardStripeDriver: AcceptOnUIMachineCreditCardDriver {
    override func startCreditCardTransaction() {        
        //Assuming they are using stripe
        let stripePublishableKey = formOptions!.paymentMethods.stripePublishableKey
        if let stripePublishableKey = stripePublishableKey {
            Stripe.setDefaultPublishableKey(stripePublishableKey)
            let card = STPCardParams(creditCardParams)
            STPAPIClient.sharedClient().createTokenWithCard(card) { [weak self] token, err in
                if let err = err {
                    self?.delegate?.creditCardTransactionDidFailWithMessage(err.localizedDescription)
                    return
                }
                
                let tokenId = token!.tokenId
                let chargeInfo = AcceptOnAPIChargeInfo(cardToken: tokenId, email: self?.creditCardParams.email)
                self?.delegate.api.chargeWithTransactionId(self?.formOptions.token.id ?? "", andChargeinfo: chargeInfo) { chargeRes, err in
                    if let err = err {
                        self?.delegate?.creditCardTransactionDidFailWithMessage(err.localizedDescription)
                        return
                    }
                    
                    self?.delegate?.creditCardTransactionDidSucceedWithChargeRes(chargeRes!)
                }
            }
        } else {
            self.delegate?.creditCardTransactionDidFailWithMessage("Stripe could not be configured")
        }
    }
}