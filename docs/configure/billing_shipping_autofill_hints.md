#Shipping, billing and Autofill hints
In both the storyboard and pure-code only examples, the `AcceptOnViewController` was configured
and had an optional `userInfo` parameter. This parameter can be configured with a set of
auto-fill hints that will automatically fill out fields when applicable and can configure
whether or not billing & shipping should be collected.

```swift
//--------------------------------------------------------------------------------
//Create our userInfo object to store our configuration options
//--------------------------------------------------------------------------------
var userInfo = AcceptOnUIMachineOptionalUserInfo()

//--------------------------------------------------------------------------------
//Autofill the user's email address
//--------------------------------------------------------------------------------
userInfo.emailAutofillHint = "jessica@yahoo.com"

//--------------------------------------------------------------------------------
//Collect, and require, billing address information
//--------------------------------------------------------------------------------
userInfo.requestsAndRequiresBillingAddress = true

//The billing address to auto-fill the user's fields with. These
//are still modifiable by the user, and if you do not provide them,
//the user will have to enter these manually
userInfo.billingAddressAutofillHints.line_1 = "123 Dale Mabry Dr."
//userInfo.billingAddressAutofillHints.line_2 = "Optional Second Line"
userInfo.billingAddressAutofillHints.city = "Tampa"
userInfo.billingAddressAutofillHints.region = "Florida"  //State/Province
userInfo.billingAddressAutofillHints.postal_code = "12345"
userInfo.billingAddressAutofillHints.country = "US"

//--------------------------------------------------------------------------------
//Collect, and require, shipping information. For payment systems that require
//that shipping costs be provided, such as apple-pay, we automatically
//set these as "Shipping Included" and set the shipping fee to `$0` on 
//any necessary shipping information fields.
//--------------------------------------------------------------------------------
userInfo.requestsAndRequiresShippingAddress = true

//The shipping address to auto-fill the user's fields with. These
//are still modifiable by the user, and if you do not provide them,
//the user will have to enter these manually
userInfo.shippingAddressAutofillHints.line_1 = "123 Dale Mabry Dr."
//userInfo.shippingAddressAutofillHints.line_2 = "Optional second Line"
userInfo.shippingAddressAutofillHints.city = "Tampa"
userInfo.shippingAddressAutofillHints.region = "Florida"  //State/Province
userInfo.shippingAddressAutofillHints.postal_code = "12345"
userInfo.shippingAddressAutofillHints.country = "US"

//--------------------------------------------------------------------------------
//Set our options in our view controller before we present it
//--------------------------------------------------------------------------------
avc.userInfo = userInfo
```

> ☃ If you require both shipping & billing address information, by default, the option "Shipping Address Same" will be checkmarked so the user will not have to type additional information in.

If you set the shipping and billing information to required via the requisite flags, this information
will appear in your accepton-on meta-data as:
```javascript
{
  billing_address: {
    line_1: '',
    line_2: '',
    city: '',
    region: '',
    postal_code: '',
    country: ''
  },
  shipping_address_same: true,
  shipping_address: {
    line_1: '',
    line_2: '',
    city: '',
    region: '',
    postal_code: '',
    country: ''
  }
}
```
