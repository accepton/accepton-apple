#import <Foundation/Foundation.h>

/// Interprets NSError objects of domain BTHTTPErrorDomain, code
/// BTHTTPErrorCodeClientError (status code 422) for Drop-In UI Components.
@interface BTDropInErrorState : NSObject

/// Initializes a new error state object returned by
/// saveCardWithNumber:expirationMonth:expirationYear:cvv:postalCode:validate:success:failure:.
///
/// @param error The error to interpret
///
/// @return a new error state instance
- (instancetype)initWithError:(NSError *)error;

/// Top-level description of error
@property (nonatomic, copy, readonly) NSString *errorTitle;

/// Set of invalid fields to highlight, each represented as a boxed BTUICardFormField
@property (nonatomic, strong, readonly) NSSet *highlightedFields;

@end
