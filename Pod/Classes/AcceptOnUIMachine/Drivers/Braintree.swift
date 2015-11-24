import UIKit
import Braintree

extension BTCard {
    convenience init(_ creditCardParams: AcceptOnUIMachineCreditCardParams) {
        self.init()
        self.number = creditCardParams.number
        self.expirationMonth = creditCardParams.expMonth ?? ""
        self.expirationYear = creditCardParams.expYear
    }
}

class AcceptOnUIMachineCreditCardBraintreeDriver : AcceptOnUIMachineCreditCardDriver {
    override func startCreditCardTransaction() {
        if let nonce = formOptions.paymentMethods.braintreeNonce {
            guard let api = BTAPIClient(authorization: nonce) else {
                self.delegate.creditCardTransactionDidFailWithMessage("The Braintree client could not be configured")
                return
            }
            
            let cardClient = BTCardClient(APIClient: api)
            cardClient.tokenizeCard(BTCard(creditCardParams)) { nonce, err in
                if let err = err {
                    self.delegate?.creditCardTransactionDidFailWithMessage(err.localizedDescription)
                    return
                }
                
                guard let tokenId = nonce?.nonce else {
                    self.delegate?.creditCardTransactionDidFailWithMessage("Could not decode response from Braintree")
                    return
                }
                
                let chargeInfo = AcceptOnAPIChargeInfo(cardToken: tokenId, email: self.creditCardParams.email)
                self.delegate.api.chargeWithTransactionId(self.formOptions.token.id ?? "", andChargeinfo: chargeInfo) { chargeRes, err in
                    if let err = err {
                        self.delegate?.creditCardTransactionDidFailWithMessage(err.localizedDescription)
                        return
                    }
                    
                    self.delegate?.creditCardTransactionDidSucceedWithChargeRes(chargeRes!)
                }
            }
        } else {
            self.delegate.creditCardTransactionDidFailWithMessage("The Braintree publishable key could not be retrieved")
        }
    }
}