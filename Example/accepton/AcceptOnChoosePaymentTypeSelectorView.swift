//This view contains a listing of clickable payment types like 'paypal', 'applepay', etc. and sends
//a delegate event when one of them is pressed.  It is instantiated by AcceptOnChosePaymentTypeView.XIB
import UIKit
import accepton

protocol AcceptOnChoosePaymentTypeSelectorViewDelegate {
    //Returns the payment method chosen such as 'paypal', 'credit_card', etc.
    func paymentTypeSelectedWithName(name: String)
}

class AcceptOnChoosePaymentTypeSelectorView: UIView
{
    //-----------------------------------------------------------------------------------------------------
    //Property
    //-----------------------------------------------------------------------------------------------------
    //List of available payment methods to display
    var _paymentMethods: [String]?
    var paymentMethods: [String]! {
        get { return _paymentMethods! }
        
        set {
            _paymentMethods = newValue
            updatePaymentMethodsInView()
        }
    }
    
    //All the buttons are stored on a sub-view
    var paymentMethodButtonsView: UIView?
        var paymentMethodButtons: [UIButton]!
    
    //Constructors
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
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] () -> Void in
            self?.animatePaymentButtonsIn()
        }
    }
    
    override func updateConstraints() {
        super.updateConstraints()
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Drawing helpers
    //-----------------------------------------------------------------------------------------------------
    func updatePaymentMethodsInView() {
        //Remove the old buttons-view if it exists (may have called paymentMethods multiple
        //times, but you probably shouldn't have and are doing something wrong)
        paymentMethodButtons = []  //array's hold strong references to the views
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
    
    //Called near the end of updatePaymentMethodsInView because the addXXX button
    //functions don't set constraints
    func setButtonConstraints() {
        var lastTop: UIView = self.paymentMethodButtonsView!
        for (i, e) in paymentMethodButtons.enumerate() {
            e.alpha = 0
            e.snp_makeConstraints { make in
                make.width.equalTo(lastTop.snp_width)
                make.centerX.equalTo(lastTop.snp_centerX)
                
                if i == 0 {
                    make.top.equalTo(lastTop.snp_top)
                } else {
                    make.top.equalTo(lastTop.snp_bottom).offset(10)
                }
                make.height.equalTo(self.paymentMethodButtonsView!.snp_height).multipliedBy(0.25)
                return
            }
            
            lastTop = e
        }
    }
    
    //Adding various buttons, but not positioning or sizing them
    //////////////////////////////////////////////////////////////////////////////////////////
    func addPaypalButton() {
        let paypalButton = UIButton(type: .Custom)
        paymentMethodButtonsView?.addSubview(paypalButton)
        
        var image = UIImage(named: "checkout_with_paypal")
        let imageView = UIImageView(image: image)
        paypalButton.addSubview(imageView)
        imageView.snp_makeConstraints { make in
            make.margins.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        paymentMethodButtons.append(paypalButton)
    }
    
    func addCreditCardButton() {
        let paypalButton = UIButton(type: .Custom)
        paymentMethodButtonsView?.addSubview(paypalButton)
        
        var image = UIImage(named: "checkout_with_credit")
        let imageView = UIImageView(image: image)
        paypalButton.addSubview(imageView)
        imageView.snp_makeConstraints { make in
            make.margins.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        paymentMethodButtons.append(paypalButton)
    }
    
    func addApplePay() {
        let paypalButton = UIButton(type: .Custom)
        paymentMethodButtonsView?.addSubview(paypalButton)
        
        var image = UIImage(named: "checkout_with_apple_pay")
        let imageView = UIImageView(image: image)
        paypalButton.addSubview(imageView)
        imageView.snp_makeConstraints { make in
            make.margins.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        paymentMethodButtons.append(paypalButton)
    }
    //////////////////////////////////////////////////////////////////////////////////////////
    
    //Animate all the buttons in
    func animatePaymentButtonsIn() {
        for (i, e) in paymentMethodButtons.enumerate() {
            e.layer.transform = CATransform3DMakeTranslation(0, self.bounds.size.height, 0)
            e.alpha = 1
            UIView.animateWithDuration(0.8, delay: Double(i)*0.100, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                e.layer.transform = CATransform3DIdentity
                }, completion: { (res) -> Void in
                    
            })
        }
    }
}