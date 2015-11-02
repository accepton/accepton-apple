<div style='text-align: center'>
  <img src='./banner.gif' />
</div>

[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/sotownsend/accepton-apple/blob/master/LICENSE)
[![Build Status](https://travis-ci.org/sotownsend/accepton-apple.svg?branch=master)](https://travis-ci.org/sotownsend/)
[![CocoaPods Version](https://img.shields.io/cocoapods/v/accepton.svg)](https://img.shields.io/cocoapods/v/accepton-apple.svg)
[![Platform](https://img.shields.io/badge/Platforms-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-ff69b4.svg)](https://developer.apple.com)

## What is this?
*accepton-apple* is a swift library for processing payments through the [AcceptOn](http://accepton.com) API which elegantly unifies many payment providers including [PayPal](http://paypal.com), [Stripe](http://stripe.com), and **ApplePay**.  This library provides you with powerful flexibility and ease-of-use by offering both beautiful pre-made payment views and access to the well-engineered low-level primitives for those wanting to have tighter integration into their applications.

## Install via CocoaPods

[CocoaPods](http://cocoapods.org) is a convenient dependency manager for XCode projects. If you haven't already, you may install *CocoaPods*
with:

```bash
$ gem install cocoapods
```

> Make sure you have version 0.39.0 or higher. Run `pod --version` if you're unsure. You may update cocoapods by running `gem install cocoapods`.

Once you have installed *CocoaPods*, please put the following code into your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'Accepton', '~> 0.1'
```

After you modify the `Podfile`, run `pod install` in the same directory as your modified `Podfile`.

## Install via pre-built binary
If you don't use cocoa pods, you may add the pre-built binaries to your XCode project.
<div style='text-align: center'>
  <img src='./docs/images/prebuilt_binaries.gif' width="900" />
</div>


## Usage via `AcceptOnViewController`
After choosing one of the above methods to install the Accepton iOS framework, do the following on your storyboard:

  1. Add a new view controller at the point where you want to collect a payment
  2. Add a `Present Modally` segue to the new view controller
  3. Ensure the newly created segue has the `Presentation` option set to `Over Current Context`
  4. Change the newly created View Controller's Class to `AcceptOnViewController` and the Module to `accepton`  

 >**⚠ Make sure you press enter after typing the Module and Class or XCode will not register the Class and/or Module.**
  
<div style='text-align: center'>
  <img src='./docs/images/storyboard.gif' width="900" />
</div>

Then use the following code for the view controller that contains the `button`.  

**You must change your accessToken to match the public access token given to you at the [https://accepton.com](https://accepton.com)**

```swift
import UIKit
import accepton

//This contains the 'buy the watch for $10' page on the Main.storyboard
class ViewController : UIViewController, AcceptOnViewControllerDelegate {
    override func viewDidLoad() {
    }
    
    //Segue in progress
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let avc = segue.destinationViewController as? AcceptOnViewController {
            avc.delegate = self
            
            //Name of the item you are selling
            avc.itemDescription = "My Item Description"
            
            //The cost in cents of the item
            avc.amountInCents = 100
            
            //The accessToken
            avc.accessToken = "pkey_xxxxxxxxxxxxxxx"
        }
    }
    
    //User hit the close button, no payment was completed
    func acceptOnCancelWasClicked(vc: AcceptOnViewController) {
        //Hide the accept-on UI
        vc.dismissViewControllerAnimated(true) {
        }
    }
    
    //Payment did succeed, show a confirmation message
    func acceptOnPaymentDidSucceed(vc: AcceptOnViewController) {
        //Dismiss the modal that we showed in the storyboard
        vc.dismissViewControllerAnimated(true) {
        }
        
        UIAlertView(title: "Hurray!", message: "Your widget was shipped", delegate: nil, cancelButtonTitle: "Ok").show()
    }
}
```



## Low Level Primitives
You may create more customized solutions through using the lower level api's:

  * [AcceptOnAPI](./docs/AcceptOnAPI.md) - The raw low-level networking API to talk to *AcceptOn*
  * [AcceptOnUIMachine](./docs/AcceptOnUIMachine.md) - Handles the semantics of the UI

## Libraries Used
  * [Alamofire](https://github.com/Alamofire/Alamofire/) - Elegant HTTP Networking in Swift
  * [SnapKit](http://snapkit.io) - An Autolayout DSL for iOS & OSX
  * [Stripe Payment Kit](https://github.com/stripe/PaymentKit) - Easily accept payments through stripe on iOS
  * [Paypal iOS SDK](https://github.com/paypal/PayPal-iOS-SDK) - See licensing restrictions
  * [CHRTextFieldFormatter](https://github.com/chebur/CHRTextFieldFormatter) - Elegant card-number formatting.

## Special thanks to:
  * [@HelloMany | Flat Credit-Card Icons](https://www.iconfinder.com/HelloMany) - Licensed under [CC Attribution](http://creativecommons.org/licenses/by/2.5/)

## License
*accepton-apple* is released under the MIT license. See LICENSE for details.
