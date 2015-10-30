import UIKit

@objc protocol AcceptOnUICreditCardValidatableFieldDelegate {
    func validatableFieldTapped(field: AcceptOnUICreditCardValidatableField, withName: String?)
}

class AcceptOnUICreditCardValidatableField : UIView {
    //-----------------------------------------------------------------------------------------------------
    //Property
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

        get {
            return _responderView
        }
    }
    
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
    
    let originalBorderColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1).CGColor
    func defaultInit() {
        self.layer.borderColor = originalBorderColor
        self.layer.borderWidth = 1
        self.layer.masksToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: "viewTapped")
        tap.delaysTouchesBegan = false
        tap.delaysTouchesEnded = false
        self.addGestureRecognizer(tap)
    }
    
    func viewTapped() {
        self.delegate?.validatableFieldTapped(self, withName: name)
        
        responderView?.userInteractionEnabled = true
        responderView?.becomeFirstResponder()
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
    
    override func updateConstraints() {
        super.updateConstraints()
    }
    
    //Set error, or hide with nil
    var _error: String?
    var error: String? {
        get {
            return _error
        }
        
        set {
            if (newValue != nil) {
                let anim = CABasicAnimation(keyPath: "borderColor")
                anim.beginTime = 0
                anim.duration = 0.3
                anim.fromValue = UIColor.clearColor().CGColor
                anim.toValue = UIColor(red:0.871, green:0.267, blue:0.220, alpha: 0.6).CGColor
                self.layer.addAnimation(anim, forKey: "error")
                self.layer.borderColor = UIColor(red:0.871, green:0.267, blue:0.220, alpha: 0.6).CGColor
                
                let anim2 = CABasicAnimation(keyPath: "borderWidth")
                anim2.beginTime = 0
                anim2.duration = 0.5
                anim2.fromValue = 1
                anim2.toValue = 0.5
                
                self.layer.addAnimation(anim2, forKey: "borderError")

            } else {
                self.layer.borderColor = originalBorderColor
            }
            
            _error = newValue
        }
    }
}