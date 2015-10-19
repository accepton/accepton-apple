<div style='text-align: center'>
  <img src='./banner.png' />
</div>

[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/sotownsend/accepton-apple/blob/master/LICENSE)
[![Build Status](https://travis-ci.org/sotownsend/accepton-apple.svg?branch=master)](https://travis-ci.org/sotownsend/)
[![CocoaPods Version](https://img.shields.io/cocoapods/v/accepton.svg)](https://img.shields.io/cocoapods/v/accepton-apple.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/badge/Platforms-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-ff69b4.svg)](https://developer.apple.com)

## What is this?
*accepton-apple* is a swift library for processing payments through the [AcceptOn](http://accepton.com) API which elegantly unifies many payment providers including [PayPal](http://paypal.com), [Stripe](http://stripe.com), and **ApplePay**.  This library provides you with powerful flexibility and ease-of-use by offering both beautiful pre-made payment views and access to the well-engineered low-level primitives for those wanting to have tighter integration into their applications.

## CocoaPods

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

## Carthage

[Carthage](https://github.com/Carthage/Carthage) is a dependency manager focused on simplicity that has no central repository. We rely
on github to act as our repository for Carthage.

If you haven't already, you may install *Carthage* via [Homebrew](http://brew.sh):

```bash
$ brew update
$ brew install carthage
```

Next, modify your `Cartfile` to include:

```ogdl
github "AcceptOn/AcceptOn" ~> 0.1
```

Then run `cartchage` in the same directory as your modified `Cartfile` and drag `AcceptOn.framework` into the `Frameworks` group of your *XCode* project.

## Usage
Wip

```swift
import accepton
```

## Libraries Used
  * [Alamofire](https://github.com/Alamofire/Alamofire/) - Elegant HTTP Networking in Swift

## License
*accepton-apple* is released under the MIT license. See LICENSE for details.
