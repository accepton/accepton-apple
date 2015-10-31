import UIKit
import accepton

//Notifications for all things relating to the credit card form
@objc protocol AcceptOnCreditCardFormDelegate {
    optional func creditCardFormPayWasClicked()
    optional func creditCardFormFieldWithName(name: String, wasUpdatedToString: String)
    optional func creditCardFormFieldWithNameDidFocus(name: String)
    optional func creditCardFormFocusedFieldLostFocus()
    optional func creditCardFormBackWasClicked()
}

//This contains the credit-card form that is displayed if the user hits the 'credit_card' payment
//button on setup
class AcceptOnCreditCardFormView: UIView, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource
{
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    //User input fields
    @IBOutlet weak var cardNumField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var securityField: UITextField!
    @IBOutlet weak var expMonthField: UITextField!
    @IBOutlet weak var expYearField: UITextField!
    lazy var nameToField: [String:UITextField] = [
        "email":self.emailField,
        "cardNum":self.cardNumField,
        "security":self.securityField,
        "expYear":self.expYearField,
        "expMonth":self.expMonthField
    ]
    lazy var fieldToName: [UITextField:String] = [
        self.emailField:"email",
        self.cardNumField:"cardNum",
        self.securityField:"security",
        self.expYearField:"expYear",
        self.expMonthField:"expMonth",
    ]
    
    //Picker views to show for certain input fields
    lazy var expMonthPickerView = UIPickerView()
    
    //The rounded white area of the form that contains padding
    //that is animated in
    @IBOutlet weak var roundFormArea: UIView!
    
    //Container of fields, contains the validation view (surrounds) which isn't
    //the user input field (see the xxField above)
    @IBOutlet weak var emailValidationView: AcceptOnUICreditCardValidatableField!
    @IBOutlet weak var cardNumValidationView: AcceptOnUICreditCardValidatableField!
    @IBOutlet weak var securityValidationView: AcceptOnUICreditCardValidatableField!
    @IBOutlet weak var expMonthValidationView: AcceptOnUICreditCardValidatableField!
    @IBOutlet weak var expYearValidationView: AcceptOnUICreditCardValidatableField!
    lazy var nameToValidationView: [String:AcceptOnUICreditCardValidatableField] = [
        "email":self.emailValidationView,
        "cardNum":self.cardNumValidationView,
        "security":self.securityValidationView,
        "expMonth":self.expMonthValidationView,
        "expYear":self.expYearValidationView
    ]
    
    //Bubble that contains credit-card brand to the right inside the cardNumValidationView
    @IBOutlet weak var brandPop: AcceptOnCreditCardNumBrandPop!
    
    //Labels above the validation fields
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var cardNumLabel: UILabel!
    @IBOutlet weak var securityLabel: UILabel!
    @IBOutlet weak var expYearLabel: UILabel!
    @IBOutlet weak var expMonthLabel: UILabel!
    
    //Button that says 'pay' at the bottom
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
    
    //Sends back events to a delegate
    weak var delegate: AcceptOnCreditCardFormDelegate?
    
    //AcceptOnCreditCardForm.xib root view
    var nibView: UIView!
    
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
        //Initialize AcceptOnCreditCardFormView.xib, sets the alpha to 0
        let nib = UINib(nibName: "AcceptOnCreditCardFormView", bundle: NSBundle(forClass: self.dynamicType))
        let nibInstance = nib.instantiateWithOwner(self, options: nil)
        nibView = nibInstance[0] as! UIView
        self.addSubview(nibView)
        
        //Install a gesture recognizer that will handle dismissal of the keyboard
        let gesture = UITapGestureRecognizer(target: self, action: "viewWasTapped")
        gesture.delaysTouchesBegan = false
        self.addGestureRecognizer(gesture)
        
        //Set the month field to use a picker
        expMonthPickerView.delegate = self
        expMonthPickerView.dataSource = self
        expMonthField.inputView = expMonthPickerView
        
        //Disables touch input for the fields, they will be forwarded beginFirstResponder when necessary
        //via the validation views and have no touch interaction at other times
        cardNumValidationView.responderView = cardNumField
        emailValidationView.responderView = emailField
        expYearValidationView.responderView = expYearField
        securityValidationView.responderView = securityField
        expMonthValidationView.responderView = expMonthField
        
        //Make our form area rounded
        self.roundFormArea.layer.cornerRadius = 15
        self.roundFormArea.clipsToBounds = true
        
        //Hide everything until we animate in
        self.alpha = 0
        for e in animationInOrder { e.alpha = 0 }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        animateIn()
    }
    
    var constraintsWereUpdated = false
    override func updateConstraints() {
        super.updateConstraints()
        
        //Only run custom constraints once
        if (constraintsWereUpdated) { return }
        constraintsWereUpdated = true
        
        //Make XIB full-screen
        nibView.snp_makeConstraints { make in
            make.edges.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Animation Helpers
    //-----------------------------------------------------------------------------------------------------
    var hasAnimatedIn = false  //Have we animated in yet?
    func animateIn() {
        if hasAnimatedIn { return }
        hasAnimatedIn = true
        dispatch_async(dispatch_get_main_queue()) { [weak self] () -> Void in
            for (idx, elm) in self!.animationInOrder.enumerate() {
                elm.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1)
                UIView.animateWithDuration(1, delay: NSTimeInterval(idx)/25.0+1, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.7, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                    elm.layer.transform = CATransform3DIdentity
                    elm.alpha = 1
                    }, completion: { res in
                        //Show 'unknown' for the credit-card view
                        if (elm == self?.cardNumValidationView) {
                            self?.brandPop.switchToBrandWithName("unknown")
                        }
                })
            }
            
            self?.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1)
            UIView.animateWithDuration(1, delay: 1, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self?.layer.transform = CATransform3DIdentity
                self?.alpha = 1
                }, completion: { res in
            })
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Signal / Action Handlers
    //-----------------------------------------------------------------------------------------------------
    //Dismiss keyboard
    func viewWasTapped() {
        //Resign all validation fields
        for (_, elm) in nameToValidationView.enumerate() {
            elm.1.resignFirstResponder()
        }
        
        //Notify delegate that we lost the keyboard
        self.delegate?.creditCardFormFocusedFieldLostFocus?()
    }
    
    //User hit the 'pay' button
    @IBAction func payWasClicked(sender: AnyObject) {
        delegate?.creditCardFormPayWasClicked?()
    }
    
    //-----------------------------------------------------------------------------------------------------
    //UITextFieldDelegate Handlers
    //-----------------------------------------------------------------------------------------------------
    //User updated a form option
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        //We need a field name & it needs to have some value
        guard let fieldName = fieldToName[textField] else { return true }
        guard let currentString = textField.text as NSString? else { return true }
        
        //Re-calculate string of field based on changes (we can't get the current string because it hasn't updated yet)
        let newString = currentString.stringByReplacingCharactersInRange(range, withString: string)
        
        //Field length maximums, prevent further input
        if (fieldName == "security" && (newString as NSString).length > 4) { return false }  //Don't allow security field to be more than 4 chars
        if (fieldName == "expYear" && (newString as NSString).length > 2) { return false }   //Don't allow year field to be more than 2 chars
        
        //If we reached this point, we can accept the update
        self.delegate?.creditCardFormFieldWithName?(fieldName, wasUpdatedToString: newString)
        return true
    }
    
    //User began editing a text-field
    func textFieldDidBeginEditing(textField: UITextField) {
        if let textFieldName = fieldToName[textField] {
            self.delegate?.creditCardFormFieldWithNameDidFocus?(textFieldName)
        } else {
            puts("Warning: textField in AcceptOnCreditCardFormView didn't have a name bound")
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //AcceptOnCreditCardFormDelegate handlers
    //-----------------------------------------------------------------------------------------------------
    //Credit-card type was updated; brands include visa, amex, master_card, discover, etc.
    func creditCardNumBrandWasUpdatedWithBrandName(name: String) {
        //Notify the bouncy image
        brandPop.switchToBrandWithName(name)
    }
    
    //-----------------------------------------------------------------------------------------------------
    //UIPickerFieldDelegate & UIPickerFieldDataSource Handlers
    //-----------------------------------------------------------------------------------------------------
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if pickerView == expMonthPickerView {
            let values = [
                "01 - Jan",
                "02 - Feb",
                "03 - Mar",
                "04 - Apr",
                "05 - May",
                "06 - Jun",
                "07 - July",
                "08 - Aug",
                "09 - Sep",
                "10 - Oct",
                "11 - Nov",
                "12 - Dec"
            ]
            return NSAttributedString(string: values[row], attributes: nil)
        } else {
            return nil
        }
    }
    
    //Ensure the expMonthPicker loads a default value to the UIMachine, because if we don't
    //the didSelectRow is not called if the user dosen't change from the default of 01 (Jan)
    var expMonthPickerViewDidSetDefault: Bool = false
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == expMonthPickerView {
            if (!expMonthPickerViewDidSetDefault) {
                expMonthPickerViewDidSetDefault = true
                self.delegate?.creditCardFormFieldWithName?("expMonth", wasUpdatedToString: "01")
            }
            return 12
        } else {
            return -1
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if pickerView == expMonthPickerView {
            return 1
        } else {
            return -1
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == expMonthPickerView {
            let values = [
                "01",
                "02",
                "03",
                "04",
                "05",
                "06",
                "07",
                "08",
                "09",
                "10",
                "11",
                "12"
            ]
            let value = values[row]
            
            self.expMonthField.text = value
            self.delegate?.creditCardFormFieldWithName?("expMonth", wasUpdatedToString: value)
        }
    }
    //-----------------------------------------------------------------------------------------------------
    //External / Delegate Handlers
    //-----------------------------------------------------------------------------------------------------
    //Adds an error to a field
    func showErrorForFieldWithName(name: String, withMessage msg: String) {
        nameToValidationView[name]!.error = msg
    }
    
    //Removes an error for a field
    func hideErrorForFieldWithName(name: String) {
        nameToValidationView[name]!.error = nil
    }
    
    //An error was changed, or just needs to be 'emphasized' because
    //there is already an error. Maybe a user hit 'pay' when a validation
    //error was still in effect
    func emphasizeErrorForFieldWithName(name: String, withMessage msg: String) {
        nameToValidationView[name]!.error = msg
    }
}
