import UIKit
import accepton
import SnapKit

@objc protocol AcceptOnViewControllerDelegate {
    //You should use this to close the accept-on view controller modal
    optional func acceptOnCancelWasClicked(vc: AcceptOnViewController)
}

//Works with the AcceptOnUIMachine to manage the UI behaviours
class AcceptOnViewController: UIViewController, AcceptOnUIMachineDelegate, AcceptOnCreditCardFormDelegate, AcceptOnChoosePaymentTypeViewDelegate, PayPalPaymentDelegate {
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    //The AcceptOnUIMachine that handles most of the behaviour
    var uim: AcceptOnUIMachine!
    
    //The credit-card form if a user clicks the credit-card payment option
    weak var creditCardForm: AcceptOnCreditCardFormView!
    
    //The first window with all the payment options and "Select your preferred payment option"
    weak var choosePaymentTypeView: AcceptOnChoosePaymentTypeView!
    
    //'Center' conent window where the creditCardForm, choosePaymentTypeView, etc. go
    weak var contentView: UIView?
    
    //The top-center down-arrow button shown when you open the modal
    var exitButton: AcceptOnPopButton!
    
    //Back-button shown on some pages like the credit-card form
    var backButton: AcceptOnPopButton!
    
    //Receive information back about the payment and when to dismiss this view-controller's modal
    weak var delegate: AcceptOnViewControllerDelegate?
    
    //All subviews should descend from these two views
    var _mainView: UIVisualEffectView!
    var mainView: UIView { return _mainView.contentView }
    
    //-----------------------------------------------------------------------------------------------------
    //Constructors, Initializers, and UIViewController lifecycle
    //-----------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        //We're presenting over a view-controller, the underlying view-controller
        //should be visible
        self.view.backgroundColor = UIColor.clearColor()
        
        //Create the UIMachine to handle behaviours
        uim = AcceptOnUIMachine(publicKey: "pkey_89f2cc7f2c423553")
        uim.delegate = self
        uim.beginForItemWithDescription("My Item", forAmountInCents: 125)
        
        //Setup the main blur view, all child-views should go ontop of this view, nothing
        //should go on self.view besides this
        _mainView = UIVisualEffectView()
        self.view.addSubview(_mainView)
        _mainView.snp_makeConstraints { make in
            make.size.equalTo(self.view.snp_size)
            make.center.equalTo(self.view.snp_center)
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
        
        //Back arrow
        backButton = AcceptOnPopButton()
        self.view.addSubview(backButton)
        var backArrowImage = UIImage(named: "back_arrow")
        backArrowImage = backArrowImage?.imageWithColor(UIColor.whiteColor())
        let backArrowImageView = UIImageView(image: backArrowImage)
        backButton.addSubview(backArrowImageView)
        backButton.innerView = backArrowImageView
        backButton.snp_makeConstraints { make in
            make.width.equalTo(23)
            make.height.equalTo(23)
            make.left.equalTo(self.view.snp_left).offset(20)
            make.top.equalTo(self.view.snp_top).offset(30)
            return
        }
        backButton.addTarget(self, action: "backWasClicked", forControlEvents: UIControlEvents.TouchUpInside)
        backButton.alpha = 0
        
        //Holds all content like form, buttons, etc.
        let contentView = UIView()
        self.contentView = contentView
        self.mainView.addSubview(contentView)
        contentView.snp_makeConstraints { make in
            make.top.equalTo(self.exitButton.snp_bottom)
            make.bottom.equalTo(self.view.snp_bottom)
            make.width.equalTo(self.mainView.snp_width)
            make.centerX.equalTo(self.mainView.snp_centerX)
            return
        }
        
        //Choose paypal, credit-card, etc.
        let choosePaymentTypeView = AcceptOnChoosePaymentTypeView()
        self.choosePaymentTypeView = choosePaymentTypeView
        self.mainView.addSubview(choosePaymentTypeView)
        choosePaymentTypeView.snp_makeConstraints { make in
            make.margins.equalTo(self.contentView!.snp_margins)
            return
        }
        choosePaymentTypeView.delegate = self
        choosePaymentTypeView.paymentMethods = ["paypal", "credit_card", "apple_pay"]
        choosePaymentTypeView.layer.cornerRadius = 5
    }
    
    override func viewWillAppear(animated: Bool) {
        self.animateIn()
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Signal / Action Handlers
    //-----------------------------------------------------------------------------------------------------
    func exitWasClicked() {
        //Signal our delegate that we can now exit
        self.delegate?.acceptOnCancelWasClicked?(self)
    }
    
    func backWasClicked() {
        uim.creditCardReset()
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
    //Animation Helpers
    //------------------------------------------------------------------------------------------------------
    func animateIn() {
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self._mainView.effect = UIBlurEffect(style: .Dark)
            }) { (res) -> Void in
                
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //AcceptOnUIMachineDelegate Handlers
    //-----------------------------------------------------------------------------------------------------
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
    
    //-----------------------------------------------------------------------------------------------------
    //AcceptOnCreditCardFormDelegate Handlers
    //-----------------------------------------------------------------------------------------------------
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
    
    //-----------------------------------------------------------------------------------------------------
    //AcceptOnChoosePaymentTypeViewDelegate Handlers
    //-----------------------------------------------------------------------------------------------------
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
    
    //-----------------------------------------------------------------------------------------------------
    //PayPalPaymentDelegate Handlers
    //-----------------------------------------------------------------------------------------------------
    func payPalPaymentDidCancel(paymentViewController: PayPalPaymentViewController!) {
        paymentViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController!, didCompletePayment completedPayment: PayPalPayment!) {
    }
}