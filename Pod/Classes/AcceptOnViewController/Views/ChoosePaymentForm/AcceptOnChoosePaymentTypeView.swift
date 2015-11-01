import UIKit
import accepton

@objc protocol AcceptOnChoosePaymentTypeViewDelegate {
    //Returns the payment method chosen such as 'paypal', 'credit_card', etc.
    func choosePaymentTypeWasClicked(name: String)
}

//This view contains a listing of clickable payment types like 'paypal', 'applepay', etc. and sends
//a delegate event when one of them is pressed.
class AcceptOnChoosePaymentTypeView: UIView
{
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    //List of available payment methods to display. Set when first initialized. Calls down
    //to view creation methods
    var _paymentMethods: [String]?
    var paymentMethods: [String]! {
        get { return _paymentMethods! }
        
        set {
            _paymentMethods = newValue
            updatePaymentMethodsInView()
        }
    }
    
    //Notify the delegate when a payment type was selected
    weak var delegate: AcceptOnChoosePaymentTypeViewDelegate?
    
    //All the buttons are stored on a sub-view
    var paymentMethodButtonsView: UIView?
        var paymentMethodButtonsToName: [UIButton:String]!  //Each button is bound to the payment name
        var paymentMethodButtons: [UIButton]!               //Holds the order of the buttons
        var paymentMethodButtonAspectRatios: [Double]!      //We need the aspect ratio of the embedded image
    
    //"Select your preffered payment method"
    lazy var headerLabel = UILabel()
    
    //-----------------------------------------------------------------------------------------------------
    //Constructors, Initializers, and UIView lifecycle
    //-----------------------------------------------------------------------------------------------------
    override init(frame: CGRect) {
        super.init(frame: frame)
        defaultInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        defaultInit()
    }
    
    convenience init() {
        self.init(frame: CGRectZero)
    }
    
    func defaultInit() {
        //Add a header / title label
        self.addSubview(headerLabel)
        headerLabel.text = "Please select your preferred payment method"
        headerLabel.numberOfLines = 2
        headerLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        headerLabel.font = UIFont(name: "HelveticaNeue-Light", size: 24)
        headerLabel.textAlignment = NSTextAlignment.Center
        headerLabel.textColor = UIColor.whiteColor()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    var constraintsWereUpdated = false
    override func updateConstraints() {
        super.updateConstraints()
        
        //Only run custom constraints once
        if (constraintsWereUpdated) { return }
        constraintsWereUpdated = true
        
        //Put header on the top
        headerLabel.snp_makeConstraints { make in
            make.top.equalTo(self.snp_top).offset(0)
            make.centerX.equalTo(self.snp_centerX)
            make.width.equalTo(self.snp_width)
            make.height.equalTo(90)
            return
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Adding payment buttons if paymentMethods is set
    //-----------------------------------------------------------------------------------------------------
    func updatePaymentMethodsInView() {
        //Remove the old buttons-view if it exists (may have called paymentMethods multiple
        //times, but you probably shouldn't have and are doing something wrong)
        paymentMethodButtons = []
        paymentMethodButtonsToName = [:]  //array's hold strong references to the views
        paymentMethodButtonAspectRatios = []
        paymentMethodButtonsView?.removeFromSuperview()
        
        //Create a new buttons-view
        paymentMethodButtonsView = UIView()
        self.addSubview(paymentMethodButtonsView!)
        paymentMethodButtonsView!.snp_makeConstraints { make in
            make.margins.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
        
        //Add necessary buttons
        for e in paymentMethods {
            switch (e) {
            case "paypal":
                addPaypalButton()
            case "credit_card":
                addCreditCardButton()
            case "apple_pay":
                addApplePay()
            default:
                puts("Warning: Unrecognized payment type for the selector view: \(e)")
            }
        }
        
        //The addXXX button functions did not actually set constraints
        setButtonConstraints()
    }
    
    //Called near the end of updatePaymentMethodsInView to set constraints of newly added
    //buttons
    func setButtonConstraints() {
        var lastTop: UIView = self.headerLabel
        let intraButtonVerticalSpace = 10
        for (i, e) in paymentMethodButtons.enumerate() {
            e.alpha = 0
            e.snp_makeConstraints { make in
                make.width.lessThanOrEqualTo(self.paymentMethodButtonsView!.snp_width)
                
                //0th lastTop is the container, which we don't need to be equal to
                if (i != 0) { make.width.equalTo(lastTop.snp_width) }
                
                make.centerX.equalTo(lastTop.snp_centerX).priority(1000)
                
                if i == 0 {
                    make.top.equalTo(lastTop.snp_bottom)
                } else {
                    make.top.equalTo(lastTop.snp_bottom).offset(intraButtonVerticalSpace)
                }
                
                make.height.lessThanOrEqualTo(self.paymentMethodButtonsView!.snp_height).multipliedBy(Double(1)/Double(self.paymentMethodButtons.count)).offset(-intraButtonVerticalSpace)
                make.width.equalTo(e.snp_height).multipliedBy(Double(self.paymentMethodButtonAspectRatios[i])).priority(1000)
            }
            
            lastTop = e
        }
    }
    
    func addPaypalButton() {
        let button = AcceptOnPopButton()
        paymentMethodButtonsView?.addSubview(button)
        
        let image = AcceptOnBundle.UIImageNamed("checkout_with_paypal")
        let imageView = UIImageView(image: image)
        button.addSubview(imageView)
        imageView.snp_makeConstraints { make in
            make.margins.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
        button.innerView = imageView
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        paymentMethodButtons.append(button)
        paymentMethodButtonsToName[button] = "paypal"
        paymentMethodButtonAspectRatios.append(Double(image!.size.width/image!.size.height))
        
        button.addTarget(self, action: "paymentMethodButtonWasClicked:", forControlEvents:.TouchUpInside)
    }
    
    func addCreditCardButton() {
        let button = AcceptOnPopButton()
        paymentMethodButtonsView?.addSubview(button)
        
        let image = AcceptOnBundle.UIImageNamed("checkout_with_credit")
        let imageView = UIImageView(image: image)
        button.addSubview(imageView)
        imageView.snp_makeConstraints { make in
            make.margins.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
        button.innerView = imageView
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        paymentMethodButtons.append(button)
        paymentMethodButtonsToName[button] = "credit_card"
        paymentMethodButtonAspectRatios.append(Double(image!.size.width/image!.size.height))
        button.addTarget(self, action: "paymentMethodButtonWasClicked:", forControlEvents:.TouchUpInside)
    }
    
    func addApplePay() {
        let button = AcceptOnPopButton()
        paymentMethodButtonsView?.addSubview(button)
        
        let image = AcceptOnBundle.UIImageNamed("checkout_with_apple_pay")
        let imageView = UIImageView(image: image)
        button.addSubview(imageView)
        imageView.snp_makeConstraints { make in
            make.margins.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
        button.innerView = imageView
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        paymentMethodButtons.append(button)
        paymentMethodButtonsToName[button] = "apple_pay"
        paymentMethodButtonAspectRatios.append(Double(image!.size.width/image!.size.height))
        button.addTarget(self, action: "paymentMethodButtonWasClicked:", forControlEvents:.TouchUpInside)
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Animation Helpers
    //-----------------------------------------------------------------------------------------------------
    var hasAnimatedPaymentButtonsIn: Bool = false
    func animatePaymentButtonsIn() {
        if (hasAnimatedPaymentButtonsIn) { return }
        hasAnimatedPaymentButtonsIn = true
        
        //Animate each button in with a slight delay
        for (i, e) in paymentMethodButtons.enumerate() {
            e.layer.transform = CATransform3DMakeTranslation(0, self.bounds.size.height, 0)
            e.alpha = 1
            UIView.animateWithDuration(0.8, delay: Double(i)*0.100, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                e.layer.transform = CATransform3DIdentity
                }, completion: { res in
            })
        }
    }
    
    //Animates a single payment button as 'active' and remove all other buttons
    var lastExcept: String!
    func animateButtonsOutExcept(name: String) {
        //Retrieve the 'other' buttons that aren't the one selected & the selected button
        let otherButtons = paymentMethodButtonsToName.filter {$0.1 != name}
        let selectedButton = paymentMethodButtonsToName.filter {$0.1 == name}[0].0
        
        //Animate buttons not selected out left
        for (i, e) in otherButtons.enumerate() {
            UIView.animateWithDuration(0.8, delay: Double(i)*0.15, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                e.0.alpha = 0
                e.0.layer.transform = CATransform3DMakeTranslation(-self.bounds.size.width/8, 0, 0)
                }) { res in
            }
        }
        
        //Animate the selected button to the bottom
        UIView.animateWithDuration(0.8, delay: Double(otherButtons.count)*0.3+0.2, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            var transform = CATransform3DIdentity
            transform = CATransform3DTranslate(transform, 0, self.bounds.size.height-selectedButton.layer.position.y, 0)
            transform = CATransform3DScale(transform, 1.3, 1.3, 1)
            selectedButton.layer.transform = transform
            }) { res in
        }
        
        //Animate the header label out top
        UIView.animateWithDuration(0.8, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.headerLabel.alpha = 0
            self.headerLabel.layer.transform = CATransform3DMakeTranslation(0, -self.bounds.size.height/4, 0)
            }) { res in
        }
        
        lastExcept = name
    }
    
    //Animate all back in
    func animateButtonsIn() {
        //Retrieve the 'other' buttons that aren't the one selected & the selected button
        let otherButtons = paymentMethodButtonsToName.filter {$0.1 != lastExcept}
        let button = paymentMethodButtonsToName.filter {$0.1 == lastExcept}[0].0
        
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            button.layer.transform = CATransform3DIdentity
            button.alpha = 1
            }) { res in
        }
        
        for (i, e) in otherButtons.enumerate() {
            UIView.animateWithDuration(0.8, delay: Double(i)*0.15+0.2, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                e.0.alpha = 1
                e.0.layer.transform = CATransform3DIdentity
                }) { res in
            }
        }
        
        UIView.animateWithDuration(0.8, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.headerLabel.alpha = 1
            self.headerLabel.layer.transform = CATransform3DIdentity
            }) { res in
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Signal / Action Handlers
    //-----------------------------------------------------------------------------------------------------
    //User clicked on a payment method button
    func paymentMethodButtonWasClicked(button: UIButton) {
        //When we created the buttons, we added the actual UIView as a hash key
        //mapping the button to the payment type.  e.g. the
        //paypal button was mapped to paymentMethodButtons[paypalButton] = "paypal"
        if let paymentType = paymentMethodButtonsToName[button] {
            delegate?.choosePaymentTypeWasClicked(paymentType)
            return
        }
        
        puts("Warning: Payment method button was clicked '\(button)' but that wasn't bound to a name")
    }
}
