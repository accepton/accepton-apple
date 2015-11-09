#AcceptOnUIMachine
A swift class that provides the support for the *semantics* of the UI layers. Each machine represents one
payment transaction flow; here is a typical *view-flow* that approximately mirrors the *state-flow* of the `AcceptOnUIMachine`.

<div style='text-align: center'>
  <img src='./images/ui_machine_view_flow.png' width="900" />
</div>

##Theory of operation
In a typical use case scenario, `AcceptOnUIMachine` will be created inside a `UIViewController` and the same `UIViewController` will act as a delegate of the `AcceptOnUIMachine` instance.  

The `UIViewController` will talk to the `AcceptOnUIMachine` by making ordinary method calls.  The `AcceptOnUIMachine` in turn, talks to the `UIViewController` through the delegate proxy set by the `UIViewController` as itself.

<div style='text-align: center'>
  <img src='./images/ui_machine_two_way.png' width="900" />
</div>

##Getting started

Let's create an example `UIViewController` that initializes a `AcceptOnUIMachine` and sets itself as the delegate to our manager instance as depicted in the diagram above:

```swift
//Create a UIViewController that acts as an AcceptOnUIMachineDelegate
class MyController : UIViewController, AcceptOnUIMachineDelegate {
  var uim: AcceptOnUIMachine!
  
  func viewDidLoad() {
    //Create a new AcceptOnUIMachine object and set ourselves as the delegate for the
    //staging API
    let uim = AcceptOnUIMachine(publicKey: "pkey_0d4502a9bf8430ae", isProduction: false)
    uim.delegate = self

    //You may also provide 'userInfo' which is additional information like a user's email. This
    //is used in various ways, such as filling out pre-filling-out the credit-card's email field
    //let userInfo = AcceptOnUIMachineOptionalUserInfo()
    //userInfo.email = "test@test.com"
    //let uim = AcceptOnUIMachine(publicKey: "pkey_0d4502a9bf8430ae", isProduction: false, userInfo: userInfo)
    //uim.delegate = self
  }
}
```

> ☃ You may either pass a `publicKey:`, or `secretKey:`  as a parameter to the AcceptOnUIMachine.  As this only handles payments, and not refunds, etc. both the public and secret provide the same level of functionality

> ☃ The last parameter, `isProduction`, can be set to true if you're using this in production.

Notice that we have declared that our controller has declared that it is complaint with the `AcceptOnUIMachineDelegate` protocol. 

> ☃ The `AcceptOnUIMachineDelegate` protocol only has optional methods so there are no compilation errors.

##Putting everything into motion

Once you have added the code annotated in the *Getting Started* section above, you will need to *start* the machine (`uim`) before you see any side-effects.  When you *start* the machine, you pass along a description and price of the object you are selling:

```swift
//Create a UIViewController that acts as an AcceptOnUIMachineDelegate
class MyController : UIViewController, AcceptOnUIMachineDelegate {
  var uim: AcceptOnUIMachine!
  
  func viewDidLoad() {
    //Create a new AcceptOnUIMachine object and set ourselves as the delegate
    let uim = AcceptOnUIMachine(publicKey: "pkey_0d4502a9bf8430ae")
    uim.delegate = self
    
    //Start the machine for a T-Shirt that costs $10
    uim.beginForItemWithDescription("T-Shirt", forAmountInCents: 1000)
  }
}
```

>⚠ `beginForItemWithDescription` can only be called once. If the machine fails to bootup, e.g. network error, you must re-create the machine to try again.

The machine will now make the necessary network requests to the `AcceptOnAPI` servers and notify the `UIViewController` when it has completed loading by calling either the `acceptOnUIMachineDidFinishBeginWithFormOptions` or `acceptOnUIMachineDidFailBegin` depending on whether or not the machine was able to reach the *AcceptOn*.  

>⚠ If you receive `acceptOnUIMachineDidFailBegin`, the machine is in an irrecoverable state.  You must re-create the machine to try again.

Here is a diagram that depicts the flow from initialization of the `AcceptOnUIMachine` to the states of either *Form Active* or *Failed load*.  Notice the pills in the center of the diagram indicate the methods being called between the view controller and machine:


<div style='text-align: center'>
  <img src='./images/ui_machine_states.png' width="900" />
</div>

Lets implement the depected *view-flow* in code:

```swift
//Create a UIViewController that acts as an AcceptOnUIMachineDelegate
class MyController : UIViewController, AcceptOnUIMachineDelegate {
  var uim: AcceptOnUIMachine!
  
  func viewDidLoad() {
    //Create a new AcceptOnUIMachine object and set ourselves as the delegate
    let uim = AcceptOnUIMachine(publicKey: "pkey_0d4502a9bf8430ae")
    uim.delegate = self
    
    //Start the machine for a T-Shirt that costs $10
    uim.beginForItemWithDescription("T-Shirt", forAmountInCents: 1000)
    
    //Show a loading screen until the machine starts up
    showLoader()
  }
  
  func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions) {
    //Success!  We should show the form requested in `AcceptOnUIMachineFormOptions` (keep on reading below)
    hideLoader()
    //loadForm()
  }
  
  func acceptOnUIMachineDidFailBegin(error: NSerror) {
    //Fail! We should show the retry button
  }
}
```

##Showing the form
Assuming you received the `acceptOnUIMachineDidFinishBeginWithFormOptions` event with your form `options`, you are now ready to hide your loading screen and show the payment form with the requisite options.  The `options` you are passed tells you which buttons to show, e.g. `paypal`, and if you should show a credit-card form.

```swift
//Expansion on the previous example code
func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions) {
  //In our VC, we showed a loader while waiting for the machine to start.  Hide this loader now.
  hideLoader()
  
  let desc = options.itemDescription  //Description you passed in beginForItemWithDescription
  let uiAmount = options.uiAmount     //Amount you passed in beginForItemWithDescription in "$xx.xx" format
  let tokenId = options.token.id      //May be useful to some.  Uses the raw token stored
  
  if (options.hasPaypalButton) {
    //Show paypal button
  }
  
  if (options.hasCreditCardForm) {
     //Show credit-card form
  }

  if (options.hasApplePay) {
    //Show apple-pay
  }
}
```

It is up to us to add the requested buttons & forms to our view. Lets go through a few different cases based on the given options in `acceptOnUIMachineDidFinishBeginWithFormOptions`

###Paypal and ApplePay Buttons
Most buttons, like paypal, require little more than adding a button to your form and then notifying the machine via a method.

  * `paypal` - Add a button and call `uim.paypalClicked()` when the button is pressed.
  * `applePay` - Add a button and call `uim.applePayClicked()` when the button is pressed.

Here is an example of the paypal flow:
<div style='text-align: center'>
  <img src='./images/ui_machine_paypal_clicked.png' width="900" />
</div>

At this point, the view controller will receive a message from the `uim` that a payment is processing via `acceptOnUIMachinePaymentIsProcessing(paymentType)`.  You should show a loading screen at this time and await an automated redirection; services will then redirect you to custom authentication screens which can either be special websites (*paypal*) or kernel-level screens (*apple pay*).  Read below in *Payment Processing* to see what to do after this point.  

###Credit card form

The credit card form has a good deal of complexity; the `uim` simplifies the process by handling the verification of the form, showing messages, determining which fields to highlight, etc.

Here is a standardized listing of all the fields in the credit-card form and an example of the error validation.
<div style='text-align: center'>
  <img src='./images/ui_machine_credit_card_fields.png' width="900" />
</div>

The ux behaviour of the credit-form is as such:

  * When a field loses focus, it is validated.
    * If the validation fails, the field is typically highlighted red and an error message is shown beside the field
      * If a field has an error that is subsequently fixed, the error goes away when the field loses focus
  * When a user `cardType` is identified, the card is usually shown next to the *cardNum* field
  * The `expMonth` field contains a drop-down selector with the available months
  * When the user hits *pay* while there are validation errors, the user is hinted that there are still validation errors.

Our `UIViewController` dosen't implement the *logic* of these behaviours; only what they entail.  The `uim` is capable of handling all the *logic* as it receives all necessary semantic events including field switches and input entry. Functions you must call to the `uim` for the credit-card form based on user actions:

>The `name` parameter is the name labeled in the credit-card example form above

```swift
//For implementations that show a credit-card form on the initial screen, you must call this in-order to receive things
//like pre-filled out email fields. For others, you must balance this call with `uim.didSwitchFromCreditCardForm`
//when you show and hide your credit-card form
uim.didSwitchToCreditCardForm()

//For some implementations, if you don't want to show the form-screen
//at the start, you may want to show it after the user clicks a 'credit_card'
//button. This provides a way to tell the engine that the credit-card
//view no-longer exists so the entries that the engine believes are in
//the credit-card view are no longer there and it should consider the
//credit-card view fresh again. You will not receive any validation
//events with this.
uid.didSwitchFromCreditCardForm()

//When a user switches to a field, e.g. clicks and brings up the keyboard, but not when the user pastes something.
//Multiple focuses will assume that the last focus is no longer active, but you should still
//call didLoseFocusWithName before calling this function (see below)
uim.creditCardFieldDidFocusWithName(name: String)

//When a user switches away from a field
uim.creditCardFieldDidLoseFocus()

//When a user updates a field, you should report the new value of that field
uim.creditCardFieldWithName(name: String, didUpdateWithString string: String)

//When the user hits the pay button
uim.creditCardPayClicked()
```

In addition to these user actions, you will also need to add the following delegate function handlers (apart of the `AcceptOnUIMachineDelegate` protocol), to your *view-controller* to receive things like field updates and validation errors.

>The `name` parameter is the name labeled in the credit-card example form above

```swift
func acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String) {
  //Animate an error in for the given field.
}

func acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName(name: String, withdMessage msg: String) {
  //Re-animate an error for the given field. The field is guaranteed to have an error
  //currently attached to it. This happens when the user hits 'pay' with validation errors
}

func acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName(name: String) {
  //Remove a validation error from a field.  Usually happens after user switches fields
  //and has fixed errors
}

//A credit-card number was typed to the point where the type could be
//deduced.  Types include "visa", "amex", "master_card", "discover" and "unknown"
func acceptOnUIMachineCreditCardTypeDidChange(type: String) {
}

//Set the field value for the credit-card form field named `name`. Used to set initial values
//such as the email if it is provided when the `uim` is initialized with a userInfo. (See intro)
func acceptOnUIMachineDidSetInitialFieldValueWithName(name: String, withValue value: String) {
}

```

At this point, the view controller will receive a message from the `uim` that a payment is processing via `acceptOnUIMachinePaymentIsProcessing("credit_card")`.  You should show a loading screen at this time.  Read below in *Payment Processing* to see what to do after this point.  

##Payment Processing

At this point, the `uim` would have received `paypalClicked`, `creditCardPayClicked`, etc. and is now processing the payment request.  You should have pushed an error view ontop of the original form and are now awaiting a response.  In order to detect this response, we need to add some delegate functions.

```swift
//Called when a payment is processing, e.g. paypal. type is 'pay_pal', 'credit_card', etc.
func acceptOnUIMachinePaymentIsProcessing(paymentType: String) {
  showPaymentProcessingLoaderOverPaymentForm()
}

//Payment succeeded, you should show a screen to notify the user that the payment went through. 
//The original payment-form and payment-form loader you pushed ontop during `acceptOnUIMachinePaymentIsProcessing` 
//should be torn down at this time.
func acceptOnUIMachinePaymentDidSucceedWithCharge(chargeInfo: [String:AnyObject]) {
  //Save this for refunding later, analytics, etc. if you wish
  let chargeId = chargeInfo["id"] as! String

  removePaypmentForm()
  removePaymentProcessingLoader()
  showSuccessPage()
}

//Something went wrong, e.g. paypal failed to login, or the user cancelled. You will
//get the error back in the next delegate method below
func acceptOnUIMachinePaymentDidAbortPaymentMethodWithName(name: String) {
  removePaymentProcessingLoader()
}

//This is always called right after acceptOnUIMachinePaymentDidAbort if it is applicable (an example
//of where it is not called is when a user hits cancel on the paypal dialog). You should always
//drop the loading screen during the DidAbort method and then show the message via this handler
func acceptOnUIMachinePaymentErrorWithMessage(message: String) {
  //Display the message on the payment form, or you could show a UIAlertView, etc.
  showError(message)
}
