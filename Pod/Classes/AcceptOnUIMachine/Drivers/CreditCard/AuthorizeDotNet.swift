import Foundation
import AuthorizeDotNetPrivate

//extension CreditCardType {
//    convenience init(_ creditCardParams: AcceptOnUIMachineCreditCardParams) {
//        self.init()
//        
//        self.cardNumber = creditCardParams.number.stringByReplacingOccurrencesOfString(" ", withString: "")
//        self.expirationDate = "\(creditCardParams.expMonth ?? "")\(creditCardParams.expYear ?? "")"
//        self.cardCode = creditCardParams.cvc
//    }
//}
//
//extension PaymentType {
//    convenience init(_ creditCardParams: AcceptOnUIMachineCreditCardParams) {
//        self.init()
//        
//        self.creditCard = CreditCardType(creditCardParams)
//    }
//}
//
//extension LineItemType {
//    convenience init(_ formOptions: AcceptOnUIMachineFormOptions) {
//        self.init()
//        
//        self.itemName = formOptions.itemDescription
//        self.itemDescription = formOptions.itemDescription
//        self.itemQuantity = "1"
//        self.itemPrice = USDCents(formOptions.amountInCents).usdDollarCentsString
//        self.itemID = formOptions.token.id
//    }
//}
//
//extension TransactionRequestType {
//    convenience init(_ formOptions: AcceptOnUIMachineFormOptions) {
//        self.init()
//        
//        self.amount = USDCents(formOptions.amountInCents).usdDollarCentsString
//        
//        self.payment = PaymentType(formOptions.creditCardParams!)
//        
//        let tax = ExtendedAmountType()
//        tax.name = "Tax"
//        tax.amount = "0"
//        
//        let shipping = ExtendedAmountType()
//        shipping.name = "Shipping"
//        shipping.amount = "0"
//        
//        self.tax = tax
//        self.shipping = shipping
//    }
//}

extension CreateTransactionRequest {
    convenience init(_ formOptions: AcceptOnUIMachineFormOptions) {
        self.init()
        
        self.transactionRequest = TransactionRequestType(formOptions)
        self.transactionType = AUTH_ONLY
        self.anetApiRequest.merchantAuthentication.transactionKey = ""
        

        self.anetApiRequest.merchantAuthentication.mobileDeviceId = ""
//        self.anetApiRequest.merchantAuthentication.sessionToken = "ewQ6$yWU7$pTQc7bOlukqPimsAwLzPPcXPML67AqdEzDS61GzC$0vTiSN_TvOKAOmxAhsbP8B9DIJUuc95mRIR_Nfj3ytzxdBaPBIoqjiJA0ij0cMWMnbQtD04stm1atqVsQ0lhSxYF$8yQyATrnfgAA"
    }
}


class AcceptOnUIMachineCreditCardAuthorizeDotNetPlugin: AcceptOnUIMachineCreditCardDriverPlugin, AuthNetDelegate {
    override var name: String {
        return "authorize.net"
    }
    
    override func beginTransactionWithFormOptions(formOptions: AcceptOnUIMachineFormOptions) {
//        let authRequest = MobileDeviceRegistrationRequest
        
        let an = AuthNet(environment: ENV_TEST)
        let loginRequest = MobileDeviceLoginRequest()
        loginRequest.anetApiRequest.merchantAuthentication.name = ""
        loginRequest.anetApiRequest.merchantAuthentication.password = ""
        loginRequest.anetApiRequest.merchantAuthentication.mobileDeviceId = "abcd"
//        loginRequest.
//        loginRequest.mobileDevice.mobileDeviceId = "device-id"
        
//        let an = AuthNet.getInstance()
        an.delegate = self
//        an.mobileDeviceLoginRequest(loginRequest)
//        an.sessionToken = "ewQ6$yWU7$pTQc7bOlukqPimsAwLzPPcXPML67AqdEzDS61GzC$0vTiSN_TvOKAOmxAhsbP8B9DIJUuc95mRIR_Nfj3ytzxdBaPBIoqjiJA0ij0cMWMnbQtD04stm1atqVsQ0lhSxYF$8yQyATrnfgAA"
        
//        an.purchaseWithRequest(CreateTransactionRequest(formOptions))
        an.captureOnlyWithRequest(CreateTransactionRequest(formOptions))
        
//        //Assuming they are using stripe
//        let stripePublishableKey = formOptions.paymentMethods.stripePublishableKey
//        if let stripePublishableKey = stripePublishableKey {
//            Stripe.setDefaultPublishableKey(stripePublishableKey)
//            let card = STPCardParams(formOptions.creditCardParams!)
//            STPAPIClient.sharedClient().createTokenWithCard(card) { token, err in
//                if let err = err {
//                    self.delegate.creditCardPlugin(self, didFailWithMessage: err.localizedDescription)
//                    return
//                }
//                
//                let tokenId = token!.tokenId
//                self.delegate.creditCardPlugin(self, didSucceedWithNonce: tokenId)
//            }
//        } else {
//            self.delegate.creditCardPlugin(self, didFailWithMessage: "Stripe could not be configured")
//        }
    }
    
    func mobileDeviceLoginSucceeded(response: MobileDeviceLoginResponse!) {
        puts("good \(response)")
        let sesh = response.sessionToken
        
        puts("session = \(sesh)")
    }
    
    func requestFailed(response: AuthNetResponse!) {
        puts("failed \(response)")
    }
    
    func paymentSucceeded(response: CreateTransactionResponse!) {
        puts("ok: \(response)")
    }
    
    func connectionFailed(response: AuthNetResponse!) {
        puts("failed: \(response)")
    }
}