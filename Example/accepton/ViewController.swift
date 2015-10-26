import UIKit
import accepton
import SnapKit

class ViewController: UIViewController, AcceptOnUIMachineDelegate, AcceptOnCreditCardFormDelegate {
    var uim: AcceptOnUIMachine!
    @IBOutlet weak var creditCardForm: AcceptOnCreditCardFormView!
    
    override func viewDidLoad() {
        uim = AcceptOnUIMachine(publicKey: "pkey_89f2cc7f2c423553")
        uim.delegate = self
        uim.beginForItemWithDescription("My Item", forAmountInCents: 125)
        
        creditCardForm.delegate = self
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
    
    
    //AcceptOnCreditCardFormViewDelegate
    func creditCardFormPayWasClicked() {
        uim.creditCardPayClicked()
    }
    
    func creditCardFormFieldWithName(name: String, wasUpdatedToString str: String) {
        uim.creditCardFieldWithName(name, didUpdateWithString: str)
    }
    
    func creditCardFormFieldWithNameDidFocus(name: String) {
        uim.creditCardFieldDidFocusWithName(name)
    }
    
    func creditCardFormFocusedFieldLostFocus() {
        uim.creditCardFieldDidLoseFocus()
    }
}