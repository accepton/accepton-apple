//
//  PayPalOAuthScopes.h
//
//  Version 2.12.4
//
//  Copyright (c) 2014, PayPal
//  All rights reserved.
//

// Currently available scope-values to which the user can be asked to consent.
// @see https://developer.paypal.com/docs/integration/direct/identity/attributes/ for more details

/// Authorize charges for future purchases paid for with PayPal.
extern NSString *const kPayPalOAuth2ScopeFuturePayments;
/// Share basic account information.
extern NSString *const kPayPalOAuth2ScopeProfile;
/// Basic Authentication.
extern NSString *const kPayPalOAuth2ScopeOpenId;
/// Share your personal and account information.
extern NSString *const kPayPalOAuth2ScopePayPalAttributes;
/// Share your email address.
extern NSString *const kPayPalOAuth2ScopeEmail;
/// Share your account address.
extern NSString *const kPayPalOAuth2ScopeAddress;
/// Share your phone number.
extern NSString *const kPayPalOAuth2ScopePhone;

