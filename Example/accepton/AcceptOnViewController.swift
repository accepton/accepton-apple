import UIKit
import accepton
import SnapKit


@objc protocol AcceptOnViewControllerDelegate {
    optional func acceptOnCancelWasClicked(vc: AcceptOnViewController)
}

@objc protocol AcceptOnViewControllerVibrancyUser {
    var vibrantContentView: UIView { get set }
}

class AcceptOnViewController: UIViewController, AcceptOnUIMachineDelegate, AcceptOnCreditCardFormDelegate, AcceptOnChoosePaymentTypeSelectorViewDelegate, PayPalPaymentDelegate {
    var uim: AcceptOnUIMachine!
    weak var creditCardForm: AcceptOnCreditCardFormView!
    weak var choosePaymentTypeView: AcceptOnChoosePaymentTypeSelectorView!
    
    //Where the choose payment, form, loader, etc. go to
    weak var contentView: UIView?
    
    var exitButton: AcceptOnPopButton!
    
    weak var delegate: AcceptOnViewControllerDelegate?
    
    //All subviews should descend from these two views
    var _mainView: UIVisualEffectView!
    var _mainVibrantView: UIVisualEffectView!
    var mainView: UIView { return _mainView.contentView }
    var mainVibrantView: UIView { return _mainVibrantView.contentView }
    
    
    override func viewWillAppear(animated: Bool) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.animateIn()
        }
    }
    
    func payPalPaymentDidCancel(paymentViewController: PayPalPaymentViewController!) {
        paymentViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController!, didCompletePayment completedPayment: PayPalPayment!) {
        
    }
    
    override func viewDidLoad() {
        
        self.view.backgroundColor = UIColor.clearColor()
        
        uim = AcceptOnUIMachine(publicKey: "pkey_89f2cc7f2c423553")
        uim.delegate = self
        uim.beginForItemWithDescription("My Item", forAmountInCents: 125)
        
        //Setup the main blur & vibrancy views
        //all views should descend from these based on their requirements, i.e. flashy
        //text should go in the mainVibrantView
        ////////////////////////////////////////////////////////////////////////////////////////////////////
        _mainView = UIVisualEffectView()
        self.view.addSubview(_mainView)
        _mainView.snp_makeConstraints { make in
            make.size.equalTo(self.view.snp_size)
            make.center.equalTo(self.view.snp_center)
            return
        }
        _mainVibrantView = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: .Dark)))
        _mainView.contentView.addSubview(_mainVibrantView)
        _mainVibrantView.snp_makeConstraints { make in
            make.margins.equalTo(_mainView.snp_margins)
            return
        }
        ////////////////////////////////////////////////////////////////////////////////////////////////////
    
        let pr = PurchaseBarView()
        self.mainView.addSubview(pr)
        pr.snp_makeConstraints { make in
            make.height.equalTo(100)
            make.bottom.equalTo(self.mainView.snp_bottom)
            make.width.equalTo(self.mainView.snp_width)
            make.centerX.equalTo(self.mainView.snp_centerX)
            return
        }
        
        //Down-arrow exit button to exit
        exitButton = AcceptOnPopButton()
        self.view.addSubview(exitButton)
        var image = UIImage(named: "down_arrow")
        image = image?.imageWithColor(UIColor.whiteColor())
        let exitButtonImageView = UIImageView(image: image)
        exitButton.addSubview(exitButtonImageView)
        exitButton.innerView = exitButtonImageView
        exitButton.snp_makeConstraints { make in
            make.width.equalTo(23)
            make.height.equalTo(23)
            make.centerX.equalTo(self.view.snp_centerX)
            make.top.equalTo(self.view.snp_top).offset(30)
            return
        }
        exitButton.addTarget(self, action: "exitWasClicked", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.addBackButton()
        
        //Holds all content like form, buttons, etc.
        let contentView = UIView()
        self.contentView = contentView
        self.mainView.addSubview(contentView)
        contentView.snp_makeConstraints { make in
            make.top.equalTo(self.exitButton.snp_bottom)
            make.bottom.equalTo(pr.snp_top)
            make.width.equalTo(self.mainView.snp_width)
            make.centerX.equalTo(self.mainView.snp_centerX)
            return
        }
        
        //Choose paypal, credit-card, etc.
        let choosePaymentTypeView = AcceptOnChoosePaymentTypeSelectorView()
        setVibrantViewForSubview(choosePaymentTypeView)
        self.choosePaymentTypeView = choosePaymentTypeView
        self.mainView.addSubview(choosePaymentTypeView)
        choosePaymentTypeView.snp_makeConstraints { make in
            make.margins.equalTo(self.contentView!.snp_margins)
            return
        }
        choosePaymentTypeView.delegate = self
        choosePaymentTypeView.paymentMethods = ["paypal", "credit_card", "apple_pay"]
        choosePaymentTypeView.layer.cornerRadius = 5
        
        let priceView = UIView()
        self.view.addSubview(priceView)
        priceView.snp_makeConstraints { make in
            make.bottom.equalTo(self.view.snp_bottom)
            make.centerX.equalTo(self.view.snp_centerX)
            make.height.equalTo(80)
            make.width.equalTo(self.view.snp_width)
            return
        }
//        priceView.backgroundColor = UIColor.whiteColor()
        
        let text = UILabel()
        self.view.addSubview(text)
        text.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        text.textColor = UIColor.whiteColor()
        text.text = "Widget"
        priceView.addSubview(text)
        priceView.snp_makeConstraints { make in
            make.left.equalTo(self.view.snp_left)
            make.height.equalTo(priceView.snp_height)
            make.top.equalTo(priceView.snp_top)
            make.bottom.equalTo(priceView.snp_bottom)
            return
        }
    }
    
    //AcceptOnUIMachineDelegate
    func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions) {
        
    }
    
    func acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String) {
        creditCardForm.showErrorForFieldWithName(name, withMessage: msg)
    }
    
    func acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName(name: String) {
        creditCardForm.hideErrorForFieldWithName(name)
    }
    
    func acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String) {
        creditCardForm.emphasizeErrorForFieldWithName(name, withMessage: msg)
    }
    
    func acceptOnUIMachineCreditCardTypeDidChange(type: String) {
        creditCardForm.creditCardNumBrandWasUpdatedWithBrandName(type)
    }
    
    //AcceptOnCreditCardFormViewDelegate
    func creditCardFormPayWasClicked() {
        uim.creditCardPayClicked()
    }
    
    func creditCardFormFieldWithName(name: String, wasUpdatedToString str: String) {
        uim.creditCardFieldWithName(name, didUpdateWithString: str)
    }
    
    func creditCardFormFieldWithNameDidFocus(name: String) {
        uim.creditCardFieldDidFocusWithName(name)
        
        //Animate view up to make room for keyboard
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [UIViewAnimationOptions.CurveEaseOut, UIViewAnimationOptions.BeginFromCurrentState, UIViewAnimationOptions.AllowUserInteraction], animations: { () -> Void in
                self.creditCardForm.layer.transform = CATransform3DMakeTranslation(0, -65, 0)
            self.creditCardForm.payButton.layer.transform = CATransform3DMakeTranslation(0, -14, 0)
            }) { (res) -> Void in
        }
    }
    
    func creditCardFormFocusedFieldLostFocus() {
        //Reset to original position
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [UIViewAnimationOptions.CurveEaseOut, UIViewAnimationOptions.BeginFromCurrentState, UIViewAnimationOptions.AllowUserInteraction], animations: { () -> Void in
            self.creditCardForm.layer.transform = CATransform3DIdentity
            self.creditCardForm.payButton.layer.transform = CATransform3DIdentity
            }) { (res) -> Void in
        }
        
        uim.creditCardFieldDidLoseFocus()
    }
    
    func choosePaymentTypeWasClicked(name: String) {
        if (name == "paypal") {
            PayPalMobile.initializeWithClientIdsForEnvironments([PayPalEnvironmentSandbox:"EAGEb2Sey28DzhMc4P0PNothBmsJggVKZK9kTBrw5bU_PP5tmRUSFSlPe62K56FGxF8LkmwA3vPn-LGh"])
            let _config = PayPalConfiguration()
            _config.acceptCreditCards = false
            _config.payPalShippingAddressOption = PayPalShippingAddressOption.PayPal
            
            let pp = PayPalPayment()
            pp.amount = 10
            pp.currencyCode = "USD"
            pp.shortDescription = "Widget"
            pp.intent = PayPalPaymentIntent.Sale
            pp.shippingAddress = PayPalShippingAddress(recipientName: "Test", withLine1: "test", withLine2: "test", withCity: "Tampa", withState: "Florida", withPostalCode: "33612", withCountryCode: "US")
            
            let ppvc = PayPalPaymentViewController(payment: pp, configuration: _config, delegate: self)
            self.presentViewController(ppvc, animated: true) { () -> Void in
            }
            return
        }
        let creditCardForm = AcceptOnCreditCardFormView(frame: CGRectZero)
        self.creditCardForm = creditCardForm
        self.mainView.addSubview(creditCardForm)
        creditCardForm.snp_makeConstraints { make in
            make.margins.equalTo(self.contentView!.snp_margins)
            return
        }
        
        creditCardForm.delegate = self
        
        //Animate exit button out
        self.exitButton.userInteractionEnabled = false
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.exitButton.alpha = 0
            self.exitButton.layer.transform = CATransform3DMakeTranslation(0, -self.view.bounds.size.height/4, 0)
            }) { (res) -> Void in
                self.exitButton.layer.transform = CATransform3DIdentity
        }
        
        //Animate back button in
        self.backButton.layer.transform = CATransform3DMakeTranslation(0, -self.view.bounds.size.height/4, 0)
        self.backButton.userInteractionEnabled = true
        UIView.animateWithDuration(0.8, delay: 1, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.backButton.alpha = 1
            self.backButton.layer.transform = CATransform3DIdentity
            }) { (res) -> Void in
        }
        
        //Animate buttons for the selection out
        choosePaymentTypeView.animateButtonsOutExcept(name)
    }
    
    func exitWasClicked() {
        self.delegate?.acceptOnCancelWasClicked?(self)
    }
    
    func creditCardFormBackClicked() {
        self.creditCardForm.removeFromSuperview()
        
        //Animate exit button in
        self.exitButton.userInteractionEnabled = true
        self.exitButton.layer.transform = CATransform3DMakeTranslation(0, -self.view.bounds.size.height/4, 0)
        UIView.animateWithDuration(0.8, delay: 0.3, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.exitButton.alpha = 1
            self.exitButton.layer.transform = CATransform3DIdentity
            }) { (res) -> Void in
        }
        
        //Animate back button out
        self.backButton.userInteractionEnabled = false
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.backButton.alpha = 0
            self.backButton.layer.transform = CATransform3DMakeTranslation(0, -self.view.bounds.size.height/4, 0)
            }) { (res) -> Void in
        }
        choosePaymentTypeView.animateButtonsIn()
    }

    //------------------------------------------------------------------------------------------------------
    //Animations
    //------------------------------------------------------------------------------------------------------
    func animateIn() {
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self._mainView.effect = UIBlurEffect(style: .Dark)
            }) { (res) -> Void in
            
        }
    }
    
    //------------------------------------------------------------------------------------------------------
    //View Management
    //------------------------------------------------------------------------------------------------------
    //A view area would normally not be needed, but we have a vibrancy view we
    //want to be able to share with subviews
    var vibrancySubviews: [UIView:UIView] = [:]
    func setVibrantViewForSubview(subview: AcceptOnViewControllerVibrancyUser) {
        let vibrancyContentSubview = UIView()
        mainVibrantView.addSubview(vibrancyContentSubview)
        vibrancyContentSubview.snp_makeConstraints { make in
            make.margins.equalTo(mainVibrantView.snp_margins)
            return
        }
        
        vibrancySubviews[subview as! UIView] = vibrancyContentSubview
        subview.vibrantContentView = vibrancyContentSubview
    }
    
    func removeVibrancySubviewForSubview(subview: AcceptOnViewControllerVibrancyUser) {
        let vibrantRemovedView = vibrancySubviews.removeValueForKey(subview as! UIView)
        if let vibrantRemovedView = vibrantRemovedView {
            vibrantRemovedView.removeFromSuperview()
        } else {
            NSException(name: "AcceptOnViewController", reason: "Tried to remove vibrancy subview for subview \(subview) but there was no vibrant view", userInfo: nil).raise()
        }
    }
    
    var backButton: AcceptOnPopButton!
    func addBackButton() {
        //Back arrow
        backButton = AcceptOnPopButton()
        self.view.addSubview(backButton)
        var image = UIImage(named: "back_arrow")
        image = image?.imageWithColor(UIColor.whiteColor())
        let exitButtonImageView = UIImageView(image: image)
        backButton.addSubview(exitButtonImageView)
        backButton.innerView = exitButtonImageView
        backButton.snp_makeConstraints { make in
            make.width.equalTo(23)
            make.height.equalTo(23)
            make.left.equalTo(self.view.snp_left).offset(20)
            make.top.equalTo(self.view.snp_top).offset(30)
            return
        }
        backButton.addTarget(self, action: "creditCardFormBackClicked", forControlEvents: UIControlEvents.TouchUpInside)
        backButton.alpha = 0
    }
}