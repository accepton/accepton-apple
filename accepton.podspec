#
# Be sure to run `pod lib lint accepton.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "accepton"
  s.version          = "0.4.10"
  s.summary          = "Beautiful payment processing for iOS"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
A swift library for processing payments through the AcceptOn API which elegantly unifies many payment providers including PayPal, Stripe, and ApplePay. This library provides you with powerful flexibility and ease-of-use by offering both beautiful pre-made payment views and access to the well-engineered low-level primitives for those wanting to have tighter integration into their applications.
                       DESC

  s.homepage         = "http://accepton.com"
  s.license          = 'MIT'
  s.author           = { "seo" => "seotownsend@icloud.com" }
  s.source           = { :git => "https://github.com/accepton/accepton-apple.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/acceptonhq'

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'accepton' => ['Pod/Assets/*.png']
  }

  s.public_header_files = 'Pod/Vendor/stub.h'
  s.source_files = 'Pod/Vendor/Paypal/*', 'Pod/Vendor/CHRTextFieldFormatter/**/*', 'Pod/Classes/**/*', 'Pod/Vendor/BUYPaymentButton/**/*', 'Pod/Vendor/Snapkit/**/*', 'Pod/Vendor/Alamofire/*', 'Pod/Vendor/Braintree/*', 'Pod/Vendor/Stripe/*', 'Pod/Vendor/stub.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.weak_framework = 'SystemConfiguration', 'MobileCoreServices', 'MessageUI', 'CoreLocation', 'Accelerate', 'PassKit'
  s.resource_bundle = {'accepton' => ['Pod/Assets/*']}
  s.vendored_libraries = 'Pod/Vendor/Paypal/libPayPalMobile.a'
  s.preserve_paths = 'Pod/Vendor/**/*'

  ## Things we have slip-streamed into Pod/Vendor/* and added a modulemap to
  #vendor_modules = %w(
    #BUYPaymentButton
    #CHRTextFieldFormatter
    #PayPal
    #Stripe
    #Braintree 
  #)
  #swift_include_paths = vendor_modules.map {|e| "${PODS_ROOT}/**"}.join(" ")

  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-ObjC', 'LIBRARY_SEARCH_PATHS' => '${SRCROOT}/**', 'USER_HEADER_SEARCH_PATHS' => "${SRCROOT}/**", 'SWIFT_INCLUDE_PATHS' => "${PODS_ROOT}/../../** ${PODS_ROOT}/../**"}
end