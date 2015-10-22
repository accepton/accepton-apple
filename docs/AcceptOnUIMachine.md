#AcceptOnUIMachine
A swift class that provides the support for the *semantics* of the UI layers. Each machine represents one
payment transaction flow.

##Usage
In a typical use case scenario, `AcceptOnUIMachine` will be created inside a `UIViewController` and the same `UIViewController` will act as a delegate of the `AcceptOnUIMachine` instance.  The `UIViewController` will receive events that determine when it should display loading screens, errors, what to display on forms, successful payment submissions, etc. The `AcceptOnUIMachine` doesn't determine the actual views to be displayed only the concepts that should be displayed.  It is up to the `UIViewController` to determine what these concepts mean.  

Let's create an example `UIViewController` that initializes a `AcceptOnUIMachine` and sets itself as the delegate to our manager instance:

```swift
//Create a UIViewController that acts as an AcceptOnUIMachineDelegate
class MyController : UIViewController, AcceptOnUIMachineDelegate {
  var uim: AcceptOnUIMachine!
  
  func viewDidLoad() {
    //Create a new AcceptOnUIMachine object and set ourselves as the delegate
    let uim = AcceptOnUIMachine(publicKey: "pkey_0d4502a9bf8430ae")
    uim.delegate = self
  }
}
```

> ☃ You may either pass a `publicKey:`, or `secretKey:`  as a parameter to the AcceptOnUIMachine.  As this only handles payments, and not refunds, etc. both the public and secret provide the same level of functionality

At this point, we have a fully initialized `AcceptOnUIMachine`.  Nothing will happened until we tell the machine to start. We do this by calling `uim.beginForItemWithDescription`.  This method signals the start of a payment flow; the machine represents the state you are in that payment flow.  That is why you provide this method with a description and price.  The machine will then request from the *AcceptOn* api's a transaction token based on our given description and price.

>⚠ `beginForItemWithDescription` can only be called once. If the machine fails to bootup, e.g. network error, you must re-create the machine to try again.

```swift
//Create a UIViewController that acts as an AcceptOnUIMachineDelegate
class MyController : UIViewController, AcceptOnUIMachineDelegate {
  var uim: AcceptOnUIMachine!
  
  func viewDidLoad() {
    //Create a new AcceptOnUIMachine object and set ourselves as the delegate
    let uim = AcceptOnUIMachine(publicKey: "pkey_0d4502a9bf8430ae")
    uim.delegate = self

    //Request the machine to 'bootup'
    uim.beginForItemWithDescription("Shoes", amountInCents: 440)
  }
}
```
If you ran this code, there would be no noticeable side-effects. That is because the `uim` calls the delegate's functions when something 
happends; but we have not added any of the optional delegate methods. Let's add the two most basic of the delegate methods, `acceptOnUIMachineDidFinishBeginWithFormOptions` and
the `acceptOnUIMachineDidFailBegin`:

```swift
//Create a UIViewController that acts as an AcceptOnUIMachineDelegate
class MyController : UIViewController, AcceptOnUIMachineDelegate {
  var uim: AcceptOnUIMachine!
  
  func viewDidLoad() {
    //Create a new AcceptOnUIMachine object and set ourselves as the delegate
    let uim = AcceptOnUIMachine(publicKey: "pkey_0d4502a9bf8430ae")
    uim.delegate = self

    //Request the machine to 'bootup'
    uim.beginForItemWithDescription("Shoes", amountInCents: 440)
  }

  //You should display the form as specified by options and hide any loading screen you had showing
  func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions) {
    if (options.hasCreditCardForm) {
      //See credit-card-form section below
    }

    if (options.hasPaypalButton) {
      //See paypal-form section below
    }
  }

  //This is non-recoverable. acceptUIMachineDidFinishBeginWithFormOptions was never called.  More than likely, you
  //couldn't connect with the AcceptOn API's servers and it couldn't get the paymentMethods information needed
  //to infer form options.
  func acceptOnUIMachineDidFailBegin(error: NSError) {
    //You should display an error and possible `retry` button.
  }
}
```

After `beginForItemWithDescription` is called, one of two things can happened. Either `acceptOnUIMachineDidFinishBeginWithFormOptions` is called or
`acceptOnUIMachineDidFailBegin` is called. Before either of these two options is called, you should show a loading screen.  If the `acceptOnUIMachineDidFailBegin`
is received, it is non-recoverable and you may want to display a `retry` button and you will need to recreate the `AcceptOnUIMachine` to retry.

#### credit-card-form
If you receive the `hasCreditCardForm` as true in the form options, you should show a credit-card form with a card-number, expiriation date, and security code.

receive a `acceptOnUIMachineDidFinishBeginWithFormOptions`, then you should display the requisite form & buttons to the user.

------

Notice that we declare our view controller to be compatible with the `AcceptOnUIMachineDelegate` protocol.  This is necessary for the delegate relationship.  

At this point, this class is not functional as we still need to add some methods defined in the protocol definition by the `AcceptOnUIMachineDelegate` to our view controller class.  Notice that we marked the area to place these protocol methods, but have not yet added them.  **All protocol methods are optional** and divided into logical sub-sections.  Let's go through each section of protocol methods and show how they should be implemented and use cases for each protocol method.

##`AcceptOnUIMachineDelegate` & `AcceptOnUIMachine` methods

##Section I - Stage II Initilaziatio

###Section II - Payment Success & Failure
When a user hits the *paypal* button (if paypal is available), or the credit-card form submit button, etc. the outcome of that payment is reduced to either a payment success or failure.

```swift
  ...continued from previous `MyController` example
  /* ################################################################################ */   
  /* AcceptOnUIMachineDelegate Methods                                                */
  /* ################################################################################ */
  
  /* --------------------------------------------------- */
  /* Section I | Stage II Initialization (initial load)  */
  /* --------------------------------------------------- */
  //When a user successfully completes a payment (i.e. charge creation) through any payment provider, e.g. `paypal`, `stripe`, etc.
  func acceptOnUIMachinePaymentDidSucceedForChargeWithId(cid: String, andDescription desc: String, andUIAmount uiAmount: String, andAmountInCents amountInCents: Int) {
    //cid           - The id of this charge that completed successfully
    //desc          - The description that was part of this charge
    //uiAmount      - The amount as a string like `3.48` for 348 cents
    //amountInCents - The amount in cents as an integer
  }
  
  //When a payment fails
  func acceptOnUIMachinePaymentDidFailWithMessage(msg: String) {
    //msg - A useful string to show the user when their payment fails
   }
   
  //We have the necessary information to load the form. This happends once after
  //the uim is started. Before this event is received, you should show a loading
  //screen
  func acceptOnUIMachineDidFinishBeginWithFormOptions(xxx) {
  }
  
  //We couldn't get the needed information from the AcceptOnAPI at this time. You will
  //have to create a new `AcceptOnUIMachine` and try again
  func acceptOnUIMachineDidFailBegin(error: NSError) {
  }
}
```

###Section II - Credit Card Form
When a user types in numbers on the credit card form, typically the fields are validated on the fly and then marked with *green* or *red* on failure.  The credit-card type, e.g. *amex*, *mastercard*, etc. will highlight for the card number, and the input fields will reject invalid input.  This section handles the messages relating to the credit-card form that signal when these types of events occur.

###Signaling

###Continuation of delegate methods...

```swift
 /* ---------------------------------------------------------- */
 /* Section II | Credit Card Form Interactive Validation, etc. */
 /* ---------------------------------------------------------- */
 //When a credit-card form field has a malformed-value upon submission, dispatched within
 //the same frame of execution as the button click handler (main).  i.e. synchronous w.r.t
 //to the UI click event
 func acceptOnUIMachineCreditCardFormErrorForFieldWithName(fieldName: String, msg: String) {
 }
  
 //When a credit-card form field is `good` and typically goes green once the user types in
 //enough information.  You should not show an incorrect form field until after the user
 //has hit submit.  This should only show a green (isValid) field or nothing at all.
 func acceptOnUIMachineCrediCardFormValidatedFieldWithName(fieldName: String, isValid: Bool) {
 }
  
 //When a credit-card form field, like card number, should be updated. You may still use a UIInputField 
 //to collect inputs but should prevent the field from updating from the input itself. Just capture the
 //changes and relay it to the field
 func acceptOnUIMachineCrediCardFormUpdateValueForField(fieldName: String) {
 }
 
 //The given field should be targeted for entry.
 func acceptOnUIMachineCreditCardFormShouldFocusOnField(fieldName: String) {
 }
```
