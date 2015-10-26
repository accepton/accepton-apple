import UIKit
import accepton

@objc protocol AcceptOnCreditCardFormDelegate {
    optional func creditCardFormPayWasClicked()
    optional func creditCardFormFieldWithName(name: String, wasUpdatedToString: String)
    optional func creditCardFormFieldWithNameDidFocus(name: String)
    optional func creditCardFormFocusedFieldLostFocus()
}

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
    
    func defaultInit() {
        let nib = UINib(nibName: "AcceptOnCreditCardFormView", bundle: NSBundle(forClass: self.dynamicType))
        let nibInstance = nib.instantiateWithOwner(self, options: nil)
        let view = nibInstance[0] as! UIView
        
        self.addSubview(view)
        view.snp_makeConstraints { make in
            make.edges.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
        
        let gesture = UITapGestureRecognizer(target: self, action: "viewTapped")
        gesture.delaysTouchesBegan = false
        self.addGestureRecognizer(gesture)
    }
    
    //Dismiss keyboard
    func viewTapped() {
        for (idx, elm) in nameToField.enumerate() {
            elm.1.resignFirstResponder()
        }
        
        self.delegate?.creditCardFormFocusedFieldLostFocus?()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
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
    
    @IBAction func payWasClicked(sender: AnyObject) {
       delegate?.creditCardFormPayWasClicked?()
    }
    
    //UITextFieldDelegate
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        //Calculate the new value of the field (this is called before it is updated)
        let currentString = textField.text as NSString?
        if let currentString = currentString {
            let newString = currentString.stringByReplacingCharactersInRange(range, withString: string)
            self.delegate?.creditCardFormFieldWithName?(fieldToName[textField] ?? "email", wasUpdatedToString: newString)
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if let textFieldName = fieldToName[textField] {
            self.delegate?.creditCardFormFieldWithNameDidFocus?(textFieldName)
        } else {
            puts("Warning: textField didn't have a name bound")
        }
    }
}
