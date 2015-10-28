import UIKit
import accepton
import SnapKit

class ViewController: UIViewController, AcceptOnUIMachineDelegate, AcceptOnCreditCardFormDelegate {
    var uim: AcceptOnUIMachine!
    @IBOutlet weak var creditCardForm: AcceptOnCreditCardFormView!
    @IBOutlet weak var choosePaymentTypeView: AcceptOnChoosePaymentTypeSelectorView!
    
    override func viewDidLoad() {
        uim = AcceptOnUIMachine(publicKey: "pkey_89f2cc7f2c423553")
        uim.delegate = self
        uim.beginForItemWithDescription("My Item", forAmountInCents: 125)
        choosePaymentTypeView.paymentMethods = ["paypal", "credit_card", "apple_pay"]
//        creditCardForm.delegate = self
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
                self.creditCardForm.layer.transform = CATransform3DMakeTranslation(0, -130, 0)
            }) { (res) -> Void in
        }
    }
    
    func creditCardFormFocusedFieldLostFocus() {
        //Reset to original position
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [UIViewAnimationOptions.CurveEaseOut, UIViewAnimationOptions.BeginFromCurrentState, UIViewAnimationOptions.AllowUserInteraction], animations: { () -> Void in
            self.creditCardForm.layer.transform = CATransform3DIdentity
            }) { (res) -> Void in
        }
        
        uim.creditCardFieldDidLoseFocus()
    }
}