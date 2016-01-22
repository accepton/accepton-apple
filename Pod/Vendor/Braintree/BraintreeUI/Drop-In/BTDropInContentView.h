#import "BTUIThemedView.h"

#import "BraintreeUI.h"

#import "BTPaymentButton.h"

typedef NS_ENUM(NSUInteger, BTDropInContentViewStateType) {
    BTDropInContentViewStateForm = 0,
    BTDropInContentViewStatePaymentMethodsOnFile,
    BTDropInContentViewStateActivity
};

/// A thin view layer that manages Drop In subviews and their layout.
@interface BTDropInContentView : BTUIThemedView

@property (nonatomic, strong) BTUISummaryView *summaryView;
@property (nonatomic, strong) BTUICTAControl *ctaControl;
@property (nonatomic, strong) BTPaymentButton *paymentButton;
@property (nonatomic, strong) UILabel *cardFormSectionHeader;
@property (nonatomic, strong) BTUICardFormView *cardForm;

@property (nonatomic, strong) BTUIPaymentMethodView *selectedPaymentMethodView;
@property (nonatomic, strong) UIButton *changeSelectedPaymentMethodButton;

/// Whether to hide the call to action
@property (nonatomic, assign) BOOL hideCTA;

/// Whether to hide the summary banner view
@property (nonatomic, assign) BOOL hideSummary;

/// The current state
@property (nonatomic, assign) BTDropInContentViewStateType state;

///  Whether the paymentButton control is hidden
@property (nonatomic, assign) BOOL hidePaymentButton;

- (void)setState:(BTDropInContentViewStateType)newState animate:(BOOL)animate;

@end
