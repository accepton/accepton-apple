import UIKit
import accepton

@objc protocol AcceptOnCreditCardFormDelegate {
    optional func creditCardFormPayWasClicked()
    optional func creditCardFormFieldWithName(name: String, wasUpdatedToString: String)
    optional func creditCardFormFieldWithNameDidFocus(name: String)
    optional func creditCardFormFocusedFieldLostFocus()
    optional func creditCardFormBackWasClicked()
}

//This contains the credit-card form that is displayed if the user hits the 'credit_card' payment
//button on setup
class AcceptOnCreditCardFormView: UIView, UITextFieldDelegate
{
    //-----------------------------------------------------------------------------------------------------
    //Property
    //-----------------------------------------------------------------------------------------------------
    //Actual fields
    @IBOutlet weak var cardNumField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var securityField: UITextField!
    @IBOutlet weak var expYearField: UITextField!
    lazy var nameToField: [String:UITextField] = [
        "email":self.emailField, "cardNum":self.cardNumField,
        "security":self.securityField, "expYear":self.expYearField
    ]
    lazy var fieldToName: [UITextField:String] = [
        self.emailField:"email", self.cardNumField:"cardNum",
        self.securityField:"security", self.expYearField:"expYear"
    ]
    
    @IBOutlet weak var roundFormArea: UIView!
    var _vibrantContentView: UIView!
    var vibrantContentView: UIView {
        get { return _vibrantContentView }
        
        set { _vibrantContentView = newValue }
    }
    
    //Container of fields, contains the actual validation view (surrounds)
    @IBOutlet weak var emailValidationView: AcceptOnUICreditCardValidatableField!
    @IBOutlet weak var cardNumValidationView: AcceptOnUICreditCardValidatableField!
    @IBOutlet weak var securityValidationView: AcceptOnUICreditCardValidatableField!
    @IBOutlet weak var expMonthValidationView: AcceptOnUICreditCardValidatableField!
    @IBOutlet weak var expYearValidationView: AcceptOnUICreditCardValidatableField!
    lazy var nameToValidationView: [String:AcceptOnUICreditCardValidatableField] = [
        "email":self.emailValidationView, "cardNum":self.cardNumValidationView,
        "security":self.securityValidationView, "expMonth":self.expMonthValidationView,
        "expYear":self.expYearValidationView
    ]
    
    //Bubble that contains credit-card brand
    @IBOutlet weak var brandPop: AcceptOnCreditCardNumBrandPop!
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var cardNumLabel: UILabel!
    @IBOutlet weak var securityLabel: UILabel!
    @IBOutlet weak var expYearLabel: UILabel!
    @IBOutlet weak var expMonthLabel: UILabel!
    
    @IBOutlet weak var payButton: AcceptOnRoundedButton!
    
    //Order that things are animated in for the flashy intro
    lazy var animationInOrder: [UIView] = [
        self.emailLabel, self.emailValidationView,
        self.cardNumLabel, self.cardNumValidationView,
        self.securityLabel, self.securityValidationView,
        self.expYearLabel, self.expYearValidationView,
        self.expMonthLabel, self.expMonthValidationView,
        self.payButton
    ]
    var hasAnimatedIn = false
    
    weak var delegate: AcceptOnCreditCardFormDelegate?
    
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
    
    var nibView: UIView?
    func defaultInit() {
        let nib = UINib(nibName: "AcceptOnCreditCardFormView", bundle: NSBundle(forClass: self.dynamicType))
        let nibInstance = nib.instantiateWithOwner(self, options: nil)
        let view = nibInstance[0] as! UIView
        
        self.addSubview(view)
        view.snp_makeConstraints { make in
            make.edges.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
        view.alpha = 0
        nibView = view
        
        let gesture = UITapGestureRecognizer(target: self, action: "viewTapped")
        gesture.delaysTouchesBegan = false
        self.addGestureRecognizer(gesture)
        
        //Disables touch input for the fields, they will
        //be forwarded beginFirstResponder when necessary
        //and have no touch interaction at other times
        cardNumValidationView.responderView = cardNumField
        emailValidationView.responderView = emailField
        expYearValidationView.responderView = expYearField
        securityValidationView.responderView = securityField
        
        for (i, e) in animationInOrder.enumerate() {
            e.alpha = 0
        }
        
        self.alpha = 0
        
        self.roundFormArea.layer.cornerRadius = 15
        self.roundFormArea.clipsToBounds = true
    }
    
    //Dismiss keyboard
    func viewTapped() {
        for (idx, elm) in nameToValidationView.enumerate() {
            elm.1.resignFirstResponder()
        }
        
        self.delegate?.creditCardFormFocusedFieldLostFocus?()
    }
    
    func animateIn() {
        dispatch_async(dispatch_get_main_queue()) { [weak self] () -> Void in
            for (idx, elm) in self!.animationInOrder.enumerate() {
                elm.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1)
                
                elm.alpha = 0
                UIView.animateWithDuration(1, delay: NSTimeInterval(idx)/25.0+1, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.7, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                    elm.layer.transform = CATransform3DIdentity
                    elm.alpha = 1
                    }, completion: { (res) -> Void in
                        if (elm == self?.cardNumValidationView) {
                            self?.brandPop.switchToBrandWithName("unknown")
                        }
                })
            }
            
            
            self?.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1)
            UIView.animateWithDuration(1, delay: 1, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self?.layer.transform = CATransform3DIdentity
                self?.nibView!.alpha = 1
                self?.alpha = 1
                }, completion: { (res) -> Void in
                    
            })
            UIView.animateWithDuration(0.5, animations: { () -> Void in
            })
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if (hasAnimatedIn == false) {
            hasAnimatedIn = true
            animateIn()
        }
    }
    
    override func updateConstraints() {
        super.updateConstraints()
    }
    
    //Methods to be called by outsiders who want to control the form
    func showErrorForFieldWithName(name: String, withMessage msg: String) {
        nameToValidationView[name]!.error = msg
    }
    
    func hideErrorForFieldWithName(name: String) {
        nameToValidationView[name]!.error = nil
    }
    
    //An error was changed, or just needs to be 'emphasized' because
    //there is already an error. Maybe a user hit 'pay' when a validation
    //error was still in effect
    func emphasizeErrorForFieldWithName(name: String, withMessage msg: String) {
        nameToValidationView[name]!.error = msg
    }
    
    //Credit-card type was updated
    //brands include visa, amex, master_card, discover, etc.
    func creditCardNumBrandWasUpdatedWithBrandName(name: String) {
        brandPop.switchToBrandWithName(name)
    }
    
    @IBAction func payWasClicked(sender: AnyObject) {
       delegate?.creditCardFormPayWasClicked?()
    }
    
    //UITextFieldDelegate
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        //We need a field name & it needs to have some value
        guard let fieldName = fieldToName[textField] else { return true }
        guard let currentString = textField.text as NSString? else { return true }
        
        //Re-calculate string of field based on changes (we can't get the current string because it hasn't updated yet)
        let newString = currentString.stringByReplacingCharactersInRange(range, withString: string)
        
        //Field length maximums, prevent further input
        if (fieldName == "security" && currentString.length >= 4) { return false }  //Don't allow security field to be more than 4 chars
        if (fieldName == "expYear" && currentString.length >= 2) { return false }   //Don't allow year field to be more than 2 chars
        
        //If we reached this point, we can accept the update
        self.delegate?.creditCardFormFieldWithName?(fieldName, wasUpdatedToString: newString)
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if let textFieldName = fieldToName[textField] {
            self.delegate?.creditCardFormFieldWithNameDidFocus?(textFieldName)
            
        } else {
            puts("Warning: textField didn't have a name bound")
        }
    }
    
    @IBAction func backButtonClicked(sender: AnyObject) {
        self.delegate?.creditCardFormBackWasClicked?()
    }
}
