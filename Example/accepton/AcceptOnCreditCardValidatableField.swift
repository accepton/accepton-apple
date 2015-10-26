import UIKit

class AcceptOnUICreditCardValidatableField : UIView {
    //-----------------------------------------------------------------------------------------------------
    //Property
    //-----------------------------------------------------------------------------------------------------
    
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
    
    let originalBorderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1).CGColor
    func defaultInit() {
        self.layer.borderColor = originalBorderColor
        self.layer.borderWidth = 0.5
        self.layer.masksToBounds = true
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
                anim.toValue = UIColor.redColor().CGColor
                self.layer.addAnimation(anim, forKey: "error")
                self.layer.borderColor = UIColor.redColor().CGColor
                
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