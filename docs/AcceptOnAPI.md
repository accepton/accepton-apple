#AcceptOnAPI
A swift class that provides the networking primitives needed to easily communicate with the AcceptOn API.

##Usage
First we need to create an api helper object bound to either your public or private key.  Certain API requests require a private key such as requesting a refund.  

> **⚠ Do not place your secret key inside your app if it is public facing!**

```swift
import accepton

//Create an API with a public key
let api = AcceptOnAPI(publicKey: "pkey_0d4502a9bf8430ae")

//Create an API with a secret key
let api = AcceptOnAPI(secretKey: "skey_07e7927212c701b9f25c6ef891ddcdf9")
```

Now we can make requests with this API. You'll want to store the `api` object if you're using it throughout your application.  


###Create a transaction token
Many API requests require a transaction token.  I.e. many api calls are for the middle of the transaction lifetime. To start a new transaction, you must create a transaction token via this request.


In this example, we're selling a *T-Shirt* for $20 USD. At the end of the code block; we receive an *NSDictionary* object containing the response of the token object as a *NSDictionary*. You will need to keep the *token_id* around.

```swift
api.createTransactionTokenWithDescription("T-Shirt", forAmountInCents: 2000) { tokenRes, error in
  //Did we succeed?
  if (let error = error) {
    print("Failed with error: \(error)")
    return;
  }
  
  //We now have a tokenId we can use
  let tokenId = tokenRes["id"] as! String
  print("Token id: ", tokenId)  //e.g. `Token id: txn_5e140f6ca52cad46c10c45b9da670ddd`
}
```

###Get available payment methods
Answer the questions of *can I accept credit cards?*, *can I accept paypal?*, etc. The first parameter is the transactional token id that you received as part of the response in `createTransactionToken`.

```swift
api.getAvailablePaymentMethodsForTransactionWithId("txn_5e140f6ca52cad46c10c45b9da670ddd") { paymentMethods, error in
  if (let error = error) {
    print("Failed with error: \(error)")
    return;
  }
  
  //We get back a AcceptOnAPIPaymentMethodsInfo struct that tells us what available
  //payment methods we can accept. The options are not necessarily mutually
  //exclusive and may have some overlap like stripe & credit cards
  let supportsCreditCard = paymentMethods.doesSupportCreditCards
  let supportsStripe = paymentMethods.doesSupportStripe
  let supportsPaypal = paymentMethods.doesSupportPaypal
  let supportsApplePay = paymentMethods.doesSupportApplePay
}
```

###Charge a transaction token
There are multiple ways of charging a token.  Each alternative way of creating a charge is done through variations of the `AcceptOnAPIChargeInfo` with the various constructors as demonstrated below.  

Let's start with our first example of charging a credit card:

```swift
//Here we are creating a charge for a credit-card that has already been processed by a payment processor
//cardNum - The credit-card number
//expMonth / expYear - The expiration month and year as appears on the credit card
//securityCode - The 'security' code on the credit card, e.g. 3-digit AMEX
//email (optional) - The email to bind to the transaction
let charge = AcceptOnAPIChargeInfo.withCreditCardNum("1234123412341234", 
                                                 expMonth: "09", 
                                                 expYear: "14", 
                                                 securityCode: "123", 
                                                 andEmail: nil)

api.chargeWithTransactionId("txn_5e140f6ca52cad46c10c45b9da670ddd", andChargeInfo: charge) { chargeRes, error in
  if (let error = error) {
    print("Failed with error: \(error)")
    return;
  }
  
  //We now have a chargeId we can use
  let chargeId = chargeRes["id"] as! String
  print("Charge id: ", chargeId)  //e.g. `Charge id: chg_5e140f6ca52cad46c10c45b9da670ddd`
}
```

Alternatively, let's create a charge for a transaction partially handled by a 3rd party payment processor:

```swift
//Here we are creating a charge for a credit-card that has already been processed by a payment processor.
//cardToken (optional) - The payment processor token
//email (optional) - The email to bind to the transaction
let charge = AcceptOnAPIChargeInfo.withCardToken("paypal_sszt2ga35rkea764kxwn07", 
                                                  andEmail: nil)

//First parameter is the transaction id you would get in api.createTransactionTokenWithDescription
//Second parameter is the charge info object you created
api.chargeWithTransactionId("txn_5e140f6ca52cad46c10c45b9da670ddd", andChargeInfo: charge) { chargeRes, error in
  if (let error = error) {
    print("Failed with error: \(error)")
    return;
  }
  
  //We now have a chargeId we can use
  let chargeId = chargeRes["id"] as! String
  print("Charge id: ", chargeId)  //e.g. `Charge id: chg_5e140f6ca52cad46c10c45b9da670ddd`
}
```

###Issue a refund
In order to issue a refund, you must have created the api with the `secretKey` parameter.
> **⚠ Do not place your secret key inside your app if it is public facing!**

```swift
//First parameter is the transaction id you would get in api.createTransactionTokenWithDescription
//Second parameter is the ID of the original charge
//Third parameter is the amount to refund in cents from the original charge
api.refundChargeWithTransactionId("txn_5e140f6ca52cad46c10c45b9da670ddd", andChargeId: "chg_oydyquhp39", forAmountInCends: 99) { refundRes, error in
  if (let error = error) {
    print("Failed with error: \(error)")
    return;
  }
  
  //We now have a refundId we can use
  let refundId = refundRes["id"] as! String
  print("Refund id: ", refundId)  //e.g. `Refund id: ref_5e140f6ca52cad46c10c45b9da670ddd`
}
```

## Better Error Handling
Each *API* method has the potential of returning an `error` which is of type `NSError`.  You may compare this `error` object for it's code based on the following enumeration members for the `AcceptOnAPIError`.  All errors are part of the `com.accepton.api.error` Domain.

Possible Error Codes:

  * `AcceptOnAPIError.Code.BadRequest` - Your request is invalid.
  * `AcceptOnAPIError.Code.Unauthorized` - Your API key is wrong.
  * `AcceptOnAPIError.Code.NotFound` - The specified resource could not be found.
  * `AcceptOnAPIIError.Code.InternalServerError` - We had a problem with our server. Try again later.
  * `AcceptOnAPIError.Code.ServiceUnavailable` - We're temporarily offline for maintenance.  Please try again later.
  * `AcceptOnAPIError.Code.NetworkIssues` - The client is having issues connecting to the internet.

Let's do an example of better error handling for requesting the transaction token:

```swift
api.createTransactionTokenWithDescription("T-Shirt", forAmountInCents: 2000) { tokenRes, error in
  //Did we succeed?
  if (let error = error) {
    switch error {
      case AcceptOnAPIError.Code.InternalServerError:
        print("Failed because AcceptOn is offline, \(error)")
      case AcceptOnAPIError.Code.NetworkIssues:
        print("Failed because your network connection is not available, \(error)")
      default:
        print("Failed for an unknown error, \(error)")
    }
    return
  }
  
  //We now have a tokenId we can use
  let tokenId = tokenRes["id"] as! String
  print("Token id: ", tokenId)  //e.g. `Token id: txn_5e140f6ca52cad46c10c45b9da670ddd`
}
```