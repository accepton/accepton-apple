#import <UIKit/UIKit.h>
#import "BTUIVectorArtView.h"

@class BTUI;

@interface BTUIPayPalWordmarkVectorArtView : BTUIVectorArtView

@property (nonatomic, strong) BTUI *theme;

///  Initializes a PayPal Wordmark with padding
///
///  This view includes built-in padding to ensure consistent typographical baseline alignment with Venmo and Coinbase wordmarks.
///
///  @return A PayPal Wordmark with padding
- (BTUIPayPalWordmarkVectorArtView *)initWithPadding;

///  Initializes a PayPal Wordmark
///
///  This view does not include built-in padding.
///
///  @return A PayPal Wordmark
- (BTUIPayPalWordmarkVectorArtView *)init;

@end
