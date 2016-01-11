import UIKit

@objc public protocol AcceptOnViewControllerDelegate {
    //You should use this to close the accept-on view controller modal
    optional func acceptOnCancelWasClicked(vc: AcceptOnViewController)
    
    //You should show the user that the payment was successful
    optional func acceptOnPaymentDidSucceed(vc: AcceptOnViewController, withChargeInfo chargeInfo: [String:AnyObject])
}

//Works with the AcceptOnUIMachine to manage the UI behaviours
public class AcceptOnViewController: UIViewController, AcceptOnUIMachineDelegate, AcceptOnCreditCardFormDelegate, AcceptOnChoosePaymentTypeViewDelegate, AcceptOnFillOutRemainingViewDelegate {
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
    
    //Sits at the bottom with price & title
    var priceTitleView: AcceptOnPriceTitleView!
    
    //Logo & lock at bottom
    lazy var footer = AcceptOnFooterView()
    
    //The top-center down-arrow button shown when you open the modal
    var exitButton: AcceptOnPopButton!
    
    //Back-button shown on some pages like the credit-card form
    var backButton: AcceptOnPopButton!
    
    //Receive information back about the payment and when to dismiss this view-controller's modal
    public weak var delegate: AcceptOnViewControllerDelegate?
    
    //All subviews should descend from these two views
    var _mainView: UIVisualEffectView!
    var mainView: UIView { return _mainView.contentView }
    
    //Access token, item description, and amount for AcceptOn transaction
    public var accessToken: String?
    public var isProduction: Bool = false
    public var itemDescription: String?
    public var amountInCents: Int?
    
    //Used to fill out the email field in the credit-card form, optional, etc.
    public var creditCardEmail: String?
    
    //Holds optional user email, etc.
    public var userInfo: AcceptOnUIMachineOptionalUserInfo?
    
    public var api: AcceptOnAPI {
        return uim.api
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Constructors, Initializers, and UIViewController lifecycle
    //-----------------------------------------------------------------------------------------------------
    
    override public func viewDidLoad() {
        if accessToken == nil {
            NSException(name: "AcceptOnViewController", reason: "Please set the accessToken (api key) property to your AcceptOn API key. `acceptOnViewController.accessToken = 'xxx'`", userInfo: nil).raise()
        }
        
        if itemDescription == nil {
            NSException(name: "AcceptOnViewController", reason: "Please set an itemDescription for what you are selling.  `acceptOnViewController.itemDescription = 'Shoes'`", userInfo: nil).raise()
        }
        
        if amountInCents == nil {
            NSException(name: "AcceptOnViewController", reason: "Please set an amountInCents for what you are selling.  `acceptOnViewController.amountInCents = 100`", userInfo: nil).raise()
        }
        
        //We're presenting over a view-controller, the underlying view-controller
        //should be visible
        self.view.backgroundColor = UIColor.clearColor()
        
        //Create the UIMachine to handle behaviours
        uim = AcceptOnUIMachine(publicKey: accessToken!, isProduction: isProduction, userInfo: userInfo)
        uim.delegate = self
        uim.beginForItemWithDescription(itemDescription!, forAmountInCents: amountInCents!)
        
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
        self.mainView.addSubview(exitButton)
        var image = AcceptOnBundle.UIImageNamed("down_arrow")
        image = image?.imageWithColor(UIColor.whiteColor())
        let exitButtonImageView = UIImageView(image: image)
        exitButton.addSubview(exitButtonImageView)
        exitButton.innerView = exitButtonImageView
        exitButtonImageView.contentMode = .ScaleAspectFit
        exitButton.padding = 14
        exitButton.snp_makeConstraints { make in
            make.width.equalTo(self.view.snp_width)
            make.height.equalTo(45)
            make.centerX.equalTo(self.view.snp_centerX)
            make.top.equalTo(self.view.snp_top).offset(30)
            return
        }
        exitButton.addTarget(self, action: "exitWasClicked", forControlEvents: UIControlEvents.TouchUpInside)
        
        //Back arrow
        backButton = AcceptOnPopButton()
        self.mainView.addSubview(backButton)
        var backArrowImage = AcceptOnBundle.UIImageNamed("back_arrow")
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
        
        //Footer
        self.mainView.addSubview(footer)
        footer.snp_makeConstraints { make in
            make.bottom.equalTo(self.view.snp_bottom)
            make.height.equalTo(30)
            make.centerX.equalTo(self.view.snp_centerX)
            make.width.equalTo(self.view.snp_width)
            return
        }
        
        //Show price & description at bottom
        self.priceTitleView = AcceptOnPriceTitleView()
        self.mainView.insertSubview(self.priceTitleView, belowSubview: footer)
        
        self.priceTitleView.snp_makeConstraints { make in
            make.width.equalTo(self.view.snp_width)
            make.height.equalTo(65)
            make.centerX.equalTo(self.view.snp_centerX)
            make.bottom.equalTo(self.footer.snp_top)
            return
        }
        
        //Holds all content like form, buttons, etc.
        let contentView = UIView()
        self.contentView = contentView
        self.mainView.insertSubview(contentView, belowSubview: priceTitleView)
        contentView.snp_makeConstraints { make in
            make.top.equalTo(self.exitButton.snp_bottom).offset(-10)
            make.bottom.equalTo(self.priceTitleView.snp_top)
            make.width.equalTo(self.mainView.snp_width)
            make.centerX.equalTo(self.mainView.snp_centerX)
            return
        }
        
        //Choose paypal, credit-card, etc.
        let choosePaymentTypeView = AcceptOnChoosePaymentTypeView()
        self.choosePaymentTypeView = choosePaymentTypeView
        self.contentView!.addSubview(choosePaymentTypeView)
        choosePaymentTypeView.snp_makeConstraints { make in
            make.margins.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
        choosePaymentTypeView.delegate = self
        
        //Start with loading spinner at start
        showWaitingWithAnimationAndDelay(nil)
    }
    
    override public func viewWillAppear(animated: Bool) {
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
        self.dropFromCreditCardFormToPaymentSelection()
    }
    
    //------------------------------------------------------------------------------------------------------
    //Animation & Drawing Helpers
    //------------------------------------------------------------------------------------------------------
    func animateIn() {
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self._mainView.effect = UIBlurEffect(style: .Dark)
            }) { (res) -> Void in
                
        }
    }
    
    //Show the waiting loader in the center
    var _waitingView: UIView?
    var waitingView: UIView {
        if _waitingView == nil {
            //Add actual waiting view
            _waitingView = UIView()
            _waitingView?.userInteractionEnabled = false
            self.view?.addSubview(_waitingView!)
            _waitingView!.snp_makeConstraints { make in
                make.top.equalTo(self.view.snp_top)
                make.bottom.equalTo(self.contentView!.snp_bottom)
                make.width.equalTo(self.view.snp_width)
                make.centerX.equalTo(self.view.snp_centerX)
                return
            }
            
            //Add spin loader
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
            _waitingView!.addSubview(spinner)
            spinner.snp_makeConstraints { make in
                make.center.equalTo(_waitingView!.center)
                make.size.equalTo(_waitingView!.snp_size)
                return
            }
            spinner.startAnimating()
        }
        
        return _waitingView!
    }
    
    func showWaitingWithAnimationAndDelay(delay: Double?) {
        if let delay = delay {
            waitingView.alpha = 0
            waitingView.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1)
            UIView.animateWithDuration(0.8, delay: delay, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.waitingView.alpha = 1
                self.waitingView.layer.transform = CATransform3DIdentity
                }, completion: { res in
                    
            })
        } else {
            waitingView.alpha = 1
        }
    }
    
    func hideWaitingWithAnimationAndDelay(delay: Double?) {
        if let delay = delay {
            waitingView.alpha = 1
            waitingView.layer.transform = CATransform3DIdentity
            UIView.animateWithDuration(0.8, delay: delay, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.waitingView.alpha = 0
                self.waitingView.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1)
                }, completion: { res in
                    
            })
        } else {
            waitingView.alpha = 0
        }
    }
    
    func dropFromCreditCardFormToPaymentSelection() {
        uim.didSwitchFromCreditCardForm()
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
    
    //-----------------------------------------------------------------------------------------------------
    //AcceptOnUIMachineDelegate Handlers
    //-----------------------------------------------------------------------------------------------------
    public func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions) {
        
        var paymentMethods: [String] = []
        if options.hasPaypalButton { paymentMethods.append("paypal") }
        if options.hasCreditCardForm { paymentMethods.append("credit_card") }
        if options.hasApplePay { paymentMethods.append("apple_pay") }
        choosePaymentTypeView.paymentMethods = paymentMethods
        choosePaymentTypeView.layer.cornerRadius = 5
        
        hideWaitingWithAnimationAndDelay(0);
        choosePaymentTypeView.animatePaymentButtonsIn()
        
        priceTitleView.price = options.uiAmount
        priceTitleView.desc = options.itemDescription
        priceTitleView.animateIn()
    }
    
    public func acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String) {
        creditCardForm.showErrorForFieldWithName(name, withMessage: msg)
    }
    
    public func acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName(name: String) {
        creditCardForm.hideErrorForFieldWithName(name)
    }
    
    public func acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String) {
        creditCardForm.emphasizeErrorForFieldWithName(name, withMessage: msg)
    }
    
    public func acceptOnUIMachineCreditCardTypeDidChange(type: String) {
        creditCardForm.creditCardNumBrandWasUpdatedWithBrandName(type)
    }
    
    public func acceptOnUIMachineDidSetInitialFieldValueWithName(name: String, withValue value: String) {
        switch name {
        case "email":
            creditCardForm.setInitialFieldValueWithName(name, withValue: value)
        default:
            puts("Unsupported initial field value: \(name)")
        }
    }
    
    public func acceptOnUIMachinePaymentDidAbortPaymentMethodWithName(name: String) {
        //Animate loading spinner out
        hideWaitingWithAnimationAndDelay(0.3)
        
        if name == "paypal" || name == "apple_pay" {
            //Animate exit button in
            self.exitButton.userInteractionEnabled = true
            self.exitButton.layer.transform = CATransform3DMakeTranslation(0, -self.view.bounds.size.height/4, 0)
            UIView.animateWithDuration(0.8, delay: 0.3, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.exitButton.alpha = 1
                self.exitButton.layer.transform = CATransform3DIdentity
                }) { (res) -> Void in
            }
            
            //Animate all option buttons back in
            choosePaymentTypeView.animateButtonsIn()
        } else if name == "credit_card" {
            dropFromCreditCardFormToPaymentSelection()
        }
    }
    
    public func acceptOnUIMachinePaymentIsProcessing(paymentType: String) {
        //Credit-card has a special flow as the UIMachine dosen't have the concept
        //of the credit-card being on a seperate page
        if paymentType == "credit_card" {
            //Show waiting loader
            showWaitingWithAnimationAndDelay(0.5)
            
            //Animate back button out
            self.backButton.userInteractionEnabled = false
            UIView.animateWithDuration(0.75, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.backButton.alpha = 0
                self.backButton.layer.transform = CATransform3DMakeTranslation(0, -self.view.bounds.size.height/4, 0)
                }) { (res) -> Void in
            }
            
            //Animate the credit-card form out
            UIView.animateWithDuration(0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.creditCardForm.alpha = 0
                self.creditCardForm.layer.transform = CATransform3DMakeScale(0.9, 0.9, 1)
                }) { (res) -> Void in
            }
            
            return
        }
        
        //Animate buttons for the selection out
        choosePaymentTypeView.animateButtonsOutExcept(paymentType)
        
        //Animate exit button out
        self.exitButton.userInteractionEnabled = false
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.exitButton.alpha = 0
            self.exitButton.layer.transform = CATransform3DMakeTranslation(0, -self.view.bounds.size.height/4, 0)
            }) { (res) -> Void in
                self.exitButton.layer.transform = CATransform3DIdentity
        }
        
        //Show waiting loader
        showWaitingWithAnimationAndDelay(1)
    }
    
    public func acceptOnUIMachinePaymentDidSucceedWithCharge(chargeInfo: [String:AnyObject]) {
        delegate?.acceptOnPaymentDidSucceed?(self, withChargeInfo: chargeInfo)
    }
    
    public func acceptOnUIMachinePaymentErrorWithMessage(message: String) {
        let alertView = UIAlertController(title: "Uh oh!", message: message, preferredStyle: .Alert)
        alertView.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        presentViewController(alertView, animated: true, completion: nil)
    }
    
    var fillOutView: AcceptOnFillOutRemainingView?
    var fillOutViewCompletion: ((Bool, AcceptOnUIMachineUserInfo?)->())?
    //Present using a specially created view controller applied to the root window
    var _fillOutRemainingViewController: UIViewController!
    var fillOutRemainingViewController: UIViewController! {
        get {
            if (_fillOutRemainingViewController == nil) {
                _fillOutRemainingViewController = UIViewController()
                
//                let rv = UIApplication.sharedApplication().windows.first
//                if rv == nil {
//                    NSException(name:"AcceptOnUIViewController", reason: "Tried to get the UIApplication.sharedApplication().windows.first to display the paypal view controller off of but this did not exist", userInfo: nil).raise()
//                }
//                
//                rv!.addSubview(_fillOutRemainingViewController.view)
//                _fillOutRemainingViewController.view.bounds = UIScreen.mainScreen().bounds
            }
            
            return _fillOutRemainingViewController
        }
    }
    
    var fillOutRemainingCompletion: ((Bool, AcceptOnUIMachineUserInfo?)->())!
    public func acceptOnUIMachineDidRequestAdditionalUserInfo(remainingOptions: AcceptOnFillOutRemainingOptions, completion: (Bool, AcceptOnUIMachineUserInfo?) -> ()) {
        fillOutRemainingCompletion = completion
        
        let vc = fillOutRemainingViewController
        fillOutView = AcceptOnFillOutRemainingView(remainingOptions: remainingOptions)
        vc.view.addSubview(fillOutView!)
        fillOutView!.snp_makeConstraints {
            $0.top.left.right.bottom.equalTo(0)
            return
        }
        fillOutView!.delegate = self
        fillOutViewCompletion = completion
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    
    //-----------------------------------------------------------------------------------------------------
    //AcceptOnFillOutRemainingView
    //-----------------------------------------------------------------------------------------------------
    public func fillOutRemainingDidCancel() {
        fillOutRemainingViewController.dismissViewControllerAnimated(true) {
            self._fillOutRemainingViewController.view.removeFromSuperview()
            self._fillOutRemainingViewController = nil
            self.fillOutRemainingCompletion(false, nil)
            self.fillOutRemainingCompletion = nil
        }
    }
    
    public func fillOutRemainingDidProvideInformation(userInfo: AcceptOnUIMachineUserInfo) {
        fillOutRemainingViewController.dismissViewControllerAnimated(true) {
            self._fillOutRemainingViewController.view.removeFromSuperview()
            self._fillOutRemainingViewController = nil
            self.fillOutRemainingCompletion(true, userInfo)
            self.fillOutRemainingCompletion = nil
        }
        
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
            
            //4s sizes
            let screenHeight = UIScreen.mainScreen().bounds.size.height
            if screenHeight < 500 {
                self.creditCardForm.layer.transform = CATransform3DMakeTranslation(0, -85, 0)
                self.creditCardForm.payButton.layer.transform = CATransform3DMakeTranslation(0, -15, 0)
            } else {
                self.creditCardForm.layer.transform = CATransform3DMakeTranslation(0, -55, 0)
            }
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
            uim.paypalClicked()
            
            return
        } else if (name == "apple_pay") {
            uim.applePayClicked()
        } else if (name == "credit_card") {
            //As credit-card is a special-case of the UIMachine,
            //we have to handle that by itself
            //Animate buttons for the selection out
            choosePaymentTypeView.animateButtonsOutExcept(name)
            
            //Animate exit button out
            self.exitButton.userInteractionEnabled = false
            UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.exitButton.alpha = 0
                self.exitButton.layer.transform = CATransform3DMakeTranslation(0, -self.view.bounds.size.height/4, 0)
                }) { (res) -> Void in
                    self.exitButton.layer.transform = CATransform3DIdentity
            }
            
            //Add credit-card form
            let creditCardForm = AcceptOnCreditCardFormView(frame: CGRectZero)
            self.creditCardForm = creditCardForm
            self.mainView.addSubview(creditCardForm)
            creditCardForm.snp_makeConstraints { make in
                make.margins.equalTo(self.contentView!.snp_margins)
                return
            }
            creditCardForm.delegate = self
            
            //Animate back button in
            self.backButton.layer.transform = CATransform3DMakeTranslation(0, -self.view.bounds.size.height/4, 0)
            self.backButton.userInteractionEnabled = true
            UIView.animateWithDuration(0.8, delay: 1, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.backButton.alpha = 1
                self.backButton.layer.transform = CATransform3DIdentity
                }) { (res) -> Void in
            }
            
            uim.didSwitchToCreditCardForm()
        }
    }
}