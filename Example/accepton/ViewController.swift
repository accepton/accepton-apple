import UIKit
import accepton
import SnapKit

class ViewController: UIViewController, AcceptOnUIMachineDelegate, UITextFieldDelegate {
    @IBOutlet weak var emailField: UITextField!

    var uim: AcceptOnUIMachine!
    lazy var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "textFieldShouldDismiss")
    override func viewDidLoad() {
        uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
        uim.delegate = self
        
        uim.beginForItemWithDescription("test", forAmountInCents: 100)
        
        emailField.delegate = self
        
        self.view.addGestureRecognizer(tap)
    }
    
    func textFieldShouldDismiss() {
        emailField.resignFirstResponder()
        
        uim.creditCardFieldDidLoseFocus()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions) {
        print("got options")
    }
    
    func acceptOnUIMachineDidFailBegin(error: NSError) {
        print("error")
    }
    
    func acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String) {
        highlightCreditCardField(name, withError:msg)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        uim.creditCardFieldDidFocusWithName(creditCardUIViewToFieldName(textField)!)
    }
    
    func creditCardFieldNameToUIView(name: String) -> UIView? {
        if (name == "email") {
            return emailField
        } else {
            return nil
        }
    }
    
    func creditCardUIViewToFieldName(view: UIView) -> String? {
        if (view == emailField) { return "email" }
        return nil
    }
    
    var validation: UIView?
    var text: UILabel?
    func highlightCreditCardField(name: String, withError error: String) {
        creditCardFieldNameToUIView(name)!.backgroundColor = UIColor.redColor()
        
        let view = UIView()
        self.view.addSubview(view)
        view.snp_makeConstraints { make in
            make.width.equalTo(creditCardFieldNameToUIView(name)!)
            make.height.equalTo(50)
            make.bottom.equalTo(creditCardFieldNameToUIView(name)!.snp_top).offset(-5)
            make.centerX.equalTo(creditCardFieldNameToUIView(name)!.snp_centerX)
            return
        }
        validation = view
        
        view.backgroundColor = UIColor.greenColor()
        
        let textField = UILabel()
        view.addSubview(textField)
        textField.snp_makeConstraints { make in
            make.size.equalTo(view.snp_size)
            make.center.equalTo(view.center)
            return
        }
        
        textField.text = error
        textField.font = UIFont(name: "Helvetica", size: 24)

        view.layer.transform = CATransform3DMakeScale(0.9, 0.9, 1)
        view.layer.opacity = 0
        
        textField.layer.transform = CATransform3DMakeScale(0.9, 0.9, 1)
        textField.layer.opacity = 0
        
        UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
            view.layer.transform = CATransform3DIdentity
            view.layer.opacity = 1
            }) { (Bool) -> Void in
        }
        
        text = textField
        
        view.layer.cornerRadius = 20
        
        UIView.animateWithDuration(1.2, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.3, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
            textField.layer.transform = CATransform3DIdentity
            textField.layer.opacity = 1
            }) { (Bool) -> Void in
        }
        
        
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = (emailField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        uim.creditCardFieldWithName("email", didUpdateWithString: text)
        return true
    }
    
    func acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName(name: String) {
        if let validation = validation {
            validation.removeFromSuperview()
        }
        
        emailField.backgroundColor = UIColor.whiteColor()
    }
    
    func acceptOnUIMachineEmphasizeValidationErorrForCreditCardFieldWithName(name: String, withMessage msg: String) {
        text?.text = msg
        validation?.layer.transform = CATransform3DMakeScale(1.3, 1.3, 1)
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            validation?.layer.transform = CATransform3DIdentity
            }) { (res) -> Void in
                
        }
    }
}