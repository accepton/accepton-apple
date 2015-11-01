import UIKit

@objc protocol AcceptOnUICreditCardValidatableFieldDelegate {
    func validatableFieldTapped(field: AcceptOnUICreditCardValidatableField, withName: String?)
}

//Each credit-card field contains one of these validatable fields behind it.  It containts the
//actual white oblong shape that goes red when a validation occurrs.  It does not contain
//the actual input field, etc.
class AcceptOnUICreditCardValidatableField : UIView {
    //-----------------------------------------------------------------------------------------------------
    //Constants
    //-----------------------------------------------------------------------------------------------------
    let validBorderColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1).CGColor
    let errorBorderColor = UIColor(red:0.871, green:0.267, blue:0.220, alpha: 0.6).CGColor
    
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    weak var delegate: AcceptOnUICreditCardValidatableFieldDelegate?
    var name: String?
    
    //View that gains first responder status & disabled touch when this view
    //does not have touch enabled
    weak var _responderView: UIView?
    var responderView: UIView? {
        set {
            _responderView = newValue
            _responderView?.userInteractionEnabled = false
        }
        get { return _responderView }
    }

    //Adds an error to the view, animates it in
    var _error: String?
    var error: String? {
        get { return _error }
        set {
            _error = newValue

            animateError()
        }
    }
    
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
        self.layer.borderColor = validBorderColor
        self.layer.borderWidth = 1
        self.layer.masksToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: "viewWasTapped")
        tap.delaysTouchesBegan = false
        tap.delaysTouchesEnded = false
        self.addGestureRecognizer(tap)
    }
    
    override func resignFirstResponder() -> Bool {
        responderView?.resignFirstResponder()
        responderView?.userInteractionEnabled = false
        
        return true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = self.bounds.size.height/2
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Animation helpers
    //-----------------------------------------------------------------------------------------------------
    //Animates the current error status. If the error status is nil, the field
    //is animated to no error
    func animateError() {
        //If there is an error
        if (error != nil) {
            //Animate the border color
            let anim = CABasicAnimation(keyPath: "borderColor")
            anim.beginTime = 0
            anim.duration = 0.3
            anim.toValue = errorBorderColor
            self.layer.addAnimation(anim, forKey: "error")
            self.layer.borderColor = errorBorderColor
            
            return
        }
        
        //No error, remove border color change
        self.layer.borderColor = validBorderColor
    }

    //-----------------------------------------------------------------------------------------------------
    //Signal / Action Handlers
    //-----------------------------------------------------------------------------------------------------
    //User tapped this field, gain first-responder status
    func viewWasTapped() {
        //Notify the delegate that we are the first-responder
        self.delegate?.validatableFieldTapped(self, withName: name)
        
        //Enable user-interaction temporarily
        responderView?.userInteractionEnabled = true
        responderView?.becomeFirstResponder()
    }
}
