#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif
#import "BTPaymentButton_Internal.h"
#import "BTLogger_Internal.h"
#import "BTUIVenmoButton.h"
#import "BTUIPayPalButton.h"
#import "BTUICoinbaseButton.h"
#import "BTUIHorizontalButtonStackCollectionViewFlowLayout.h"
#import "BTUIPaymentButtonCollectionViewCell.h"

NSString *BTPaymentButtonPaymentButtonCellIdentifier = @"BTPaymentButtonPaymentButtonCellIdentifier";

@interface BTPaymentButton () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *paymentButtonsCollectionView;

@property (nonatomic, strong) UIView *topBorder;
@property (nonatomic, strong) UIView *bottomBorder;

@end

@implementation BTPaymentButton

- (instancetype)initWithAPIClient:(BTAPIClient *)apiClient
                       completion:(void(^)(BTPaymentMethodNonce *paymentMethodNonce, NSError *error))completion
{
    if (self = [super init]) {
        [self setupViews];
        _apiClient = apiClient;
        _completion = [completion copy];
    }
    return self;
}

- (id)init {
    self = [super init];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupViews {
    self.clipsToBounds = YES;
    self.enabledPaymentOptions = [NSOrderedSet orderedSetWithArray:@[@"PayPal",
                                                                     @"Venmo"
                                                                     ]];

    BTUIHorizontalButtonStackCollectionViewFlowLayout *layout = [[BTUIHorizontalButtonStackCollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 0.0f;

    self.paymentButtonsCollectionView = [[UICollectionView alloc] initWithFrame:self.bounds
                                                           collectionViewLayout:layout];
    self.paymentButtonsCollectionView.accessibilityIdentifier = @"Payment Options";
    self.paymentButtonsCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.paymentButtonsCollectionView.allowsSelection = YES;
    self.paymentButtonsCollectionView.delaysContentTouches = NO;
    self.paymentButtonsCollectionView.delegate = self;
    self.paymentButtonsCollectionView.dataSource = self;
    self.paymentButtonsCollectionView.backgroundColor = [UIColor whiteColor];
    [self.paymentButtonsCollectionView registerClass:[BTUIPaymentButtonCollectionViewCell class] forCellWithReuseIdentifier:BTPaymentButtonPaymentButtonCellIdentifier];

    self.topBorder = [[UIView alloc] init];
    self.topBorder.backgroundColor = [self.theme borderColor];
    self.topBorder.translatesAutoresizingMaskIntoConstraints = NO;

    self.bottomBorder = [[UIView alloc] init];
    self.bottomBorder.backgroundColor = [self.theme borderColor];
    self.bottomBorder.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:self.paymentButtonsCollectionView];
    [self addSubview:self.topBorder];
    [self addSubview:self.bottomBorder];
}

- (CGSize)intrinsicContentSize {
    CGFloat height = self.filteredEnabledPaymentOptions.count > 0 ? 44 : 0;

    return CGSizeMake(UIViewNoIntrinsicMetric, height);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.paymentButtonsCollectionView.collectionViewLayout invalidateLayout];
}

- (void)updateConstraints {
    NSDictionary *views = @{ @"paymentButtonsCollectionView": self.paymentButtonsCollectionView,
                             @"topBorder": self.topBorder,
                             @"bottomBorder": self.bottomBorder };
    NSDictionary *metrics = @{ @"borderWidth": @(self.theme.borderWidth) };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[paymentButtonsCollectionView]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[paymentButtonsCollectionView]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[topBorder]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topBorder(==borderWidth)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomBorder]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomBorder(==borderWidth)]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [super updateConstraints];
}

#pragma mark - Accessors

- (id)application {
    if (!_application) {
        _application = [UIApplication sharedApplication];
    }
    return _application;
}

#pragma mark PaymentButton State

- (void)setEnabledPaymentOptions:(NSOrderedSet *)enabledPaymentOptions {
    _enabledPaymentOptions = enabledPaymentOptions;

    [self invalidateIntrinsicContentSize];
    [self.paymentButtonsCollectionView reloadData];
}

- (void)setConfiguration:(BTConfiguration *)configuration {
    _configuration = configuration;

    [self invalidateIntrinsicContentSize];
    [self.paymentButtonsCollectionView reloadData];
}

/// Collection of payment option strings, e.g. "PayPal"
- (NSOrderedSet *)filteredEnabledPaymentOptions {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSString *paymentOption, __unused NSDictionary<NSString *,id> * _Nullable bindings) {
        if (![[BTTokenizationService sharedService] isTypeAvailable:paymentOption]) {
            return NO; // If the payment option's framework is not present, it should never be shown
        }

        if (self.configuration == nil) {
            return YES; // Without Configuration, we can't do additional filtering.
        }

        if ([paymentOption isEqualToString:@"PayPal"]) {
            return [self.configuration.json[@"paypalEnabled"] isTrue];
        } else if ([paymentOption isEqualToString:@"Venmo"]) {
            // Directly from BTConfiguration+Venmo.m. Be sure to keep these files in sync! This
            // is intentionally not DRY so that BraintreeUI does not depend on BraintreeVenmo.
            BTJSON *venmoAccessToken = self.configuration.json[@"payWithVenmo"][@"accessToken"];
            NSURLComponents *components = [NSURLComponents componentsWithString:@"com.venmo.touch.v2://x-callback-url/vzero/auth"];
            
            BOOL isVenmoAppInstalled = [[self application] canOpenURL:components.URL];
            return venmoAccessToken.isString && [BTConfiguration isBetaEnabledPaymentOption:@"venmo"] && isVenmoAppInstalled;
        }
        // Payment option is available in the tokenization service, but BTPaymentButton does not know how
        // to check Configuration for whether it is enabled. Default to YES.
        return YES;
    }];
    return [self.enabledPaymentOptions filteredOrderedSetUsingPredicate:predicate];
}

- (BOOL)hasAvailablePaymentMethod {
    return self.filteredEnabledPaymentOptions.count > 0 ? YES : NO;
}

- (NSString *)paymentOptionForIndexPath:(NSIndexPath *)indexPath {
    return self.filteredEnabledPaymentOptions[indexPath.row];
}

#pragma mark UICollectionViewDataSource methods

- (NSInteger)collectionView:(__unused UICollectionView *)collectionView numberOfItemsInSection:(__unused NSInteger)section {
    NSParameterAssert(section == 0);
    return [self.filteredEnabledPaymentOptions count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(indexPath.section == 0);

    BTUIPaymentButtonCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:BTPaymentButtonPaymentButtonCellIdentifier
                                                                                        forIndexPath:indexPath];
    NSString *paymentOption = [self paymentOptionForIndexPath:indexPath];

    UIControl *paymentButton;
    if ([paymentOption isEqualToString:@"PayPal"]) {
        paymentButton = [[BTUIPayPalButton alloc] initWithFrame:cell.bounds];
    } else if ([paymentOption isEqualToString:@"Venmo"]) {
        paymentButton = [[BTUIVenmoButton alloc] initWithFrame:cell.bounds];
    } else if ([paymentOption isEqualToString:@"Coinbase"]) {
        paymentButton = [[BTUICoinbaseButton alloc] initWithFrame:cell.bounds];
    } else {
        [[BTLogger sharedLogger] warning:@"BTPaymentButton encountered an unexpected payment option value: %@", paymentOption];
        return cell;
    }
    paymentButton.translatesAutoresizingMaskIntoConstraints = NO;

    cell.paymentButton = paymentButton;

    [cell.contentView addSubview:paymentButton];

    NSDictionary *views = @{ @"paymentButton": paymentButton };
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[paymentButton]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[paymentButton]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];
    return cell;
}

- (void)collectionView:(__unused UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(self.apiClient, @"BTPaymentButton tapped without an apiClient. Please set a BTAPIClient on this payment button by setting the apiClient property.");
    NSAssert(self.completion, @"BTPaymentButton tapped without a completion block. Please set up a completion block on this payment button by setting the completion property.");

    NSString *paymentOption = [self paymentOptionForIndexPath:indexPath];

    if ([[BTTokenizationService sharedService] isTypeAvailable:paymentOption]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willAppSwitch:) name:BTAppSwitchWillSwitchNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAppSwitch:) name:BTAppSwitchDidSwitchNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willProcessPaymentInfo:) name:BTAppSwitchWillProcessPaymentInfoNotification object:nil];
        
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        if (self.viewControllerPresentingDelegate != nil) {
            options[BTTokenizationServiceViewPresentingDelegateOption] = self.viewControllerPresentingDelegate;
        }
        if (self.paymentRequest.additionalPayPalScopes != nil) {
            options[BTTokenizationServicePayPalScopesOption] = self.paymentRequest.additionalPayPalScopes;
        }
        
        [[BTTokenizationService sharedService] tokenizeType:paymentOption options:options withAPIClient:self.apiClient completion:self.completion];
    } else {
        [[BTLogger sharedLogger] warning:@"BTPaymentButton encountered an unexpected payment option value: %@", paymentOption];
    }
}

- (void)willAppSwitch:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BTAppSwitchWillSwitchNotification object:nil];

    id paymentDriver = notification.object;
    if ([self.appSwitchDelegate respondsToSelector:@selector(appSwitcherWillPerformAppSwitch:)]) {
        [self.appSwitchDelegate appSwitcherWillPerformAppSwitch:paymentDriver];
    }
}

- (void)didAppSwitch:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BTAppSwitchDidSwitchNotification object:nil];

    id paymentDriver = notification.object;
    BTAppSwitchTarget appSwitchTarget = [notification.userInfo[BTAppSwitchNotificationTargetKey] integerValue];
    if ([self.appSwitchDelegate respondsToSelector:@selector(appSwitcher:didPerformSwitchToTarget:)]) {
        [self.appSwitchDelegate appSwitcher:paymentDriver didPerformSwitchToTarget:appSwitchTarget];
    }
}

- (void)willProcessPaymentInfo:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BTAppSwitchWillProcessPaymentInfoNotification object:nil];

    id paymentDriver = notification.object;
    if ([self.appSwitchDelegate respondsToSelector:@selector(appSwitcherWillProcessPaymentInfo:)]) {
        [self.appSwitchDelegate appSwitcherWillProcessPaymentInfo:paymentDriver];
    }
}

@end
