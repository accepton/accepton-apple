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

class AcceptOnUIMachineCreditCardBraintreePlugin: AcceptOnUIMachineCreditCardDriverPlugin {
    override func beginTransactionWithFormOptions(formOptions: AcceptOnUIMachineFormOptions) {
        if let nonce = formOptions.paymentMethods.braintreeNonce {
            guard let api = BTAPIClient(authorization: nonce) else {
                self.delegate.creditCardPlugin(self, didFailWithMessage: "The Braintree client could not be configured")
                return
            }
            
            let cardClient = BTCardClient(APIClient: api)
            cardClient.tokenizeCard(BTCard(formOptions.creditCardParams!)) { nonce, err in
                if let err = err {
                    self.delegate.creditCardPlugin(self, didFailWithMessage: err.localizedDescription)
                    return
                }
                
                guard let tokenId = nonce?.nonce else {
                    self.delegate.creditCardPlugin(self, didFailWithMessage: "Could not decode response from Braintree")
                    return
                }
                
                self.delegate.creditCardPlugin(self, didSucceedWithNonce: tokenId)
            }
        } else {
            self.delegate.creditCardPlugin(self, didFailWithMessage: "The Braintree publishable key could not be retrieved")
        }
    }
}