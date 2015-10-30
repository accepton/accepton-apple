import UIKit

//This is a button that goes 'pop' on touch-down.  Used for back buttons, exit buttons, etc.
class AcceptOnPopButton: UIButton {
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    //Layout subviews allowed to continue?
    var layoutSubviewsEnabled: Bool = true
    
    var padding: CGFloat = 0
    
    //View to animate, should be added by an external view
    //during configuration
    var innerView: UIView!
    
    @IBInspectable var scale: CGFloat = 0.8
    
    //------------------------------------------------------------------------------------------------------
    //Constructors
    //------------------------------------------------------------------------------------------------------
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        viewDidLoad()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewDidLoad()
    }
    
    func viewDidLoad() {
        //Event handling
        self.addTarget(self, action: "buttonClick", forControlEvents: UIControlEvents.TouchUpInside)
        self.addTarget(self, action: "buttonDown", forControlEvents: [UIControlEvents.TouchDown, UIControlEvents.TouchDragEnter])
        self.addTarget(self, action: "buttonCancel", forControlEvents: [UIControlEvents.TouchCancel, UIControlEvents.TouchDragExit])
    }
    
    //------------------------------------------------------------------------------------------------------
    //View Rendering
    //------------------------------------------------------------------------------------------------------
    override func layoutSubviews() {
        if (!layoutSubviewsEnabled) {
            return
        }
        
        self.innerView.frame = CGRectInset(self.bounds, self.padding, self.padding)
    }
    
    //------------------------------------------------------------------------------------------------------
    //Event Handling
    //------------------------------------------------------------------------------------------------------
    func buttonDown() {
        self.layoutSubviewsEnabled = false
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: [UIViewAnimationOptions.CurveEaseOut, UIViewAnimationOptions.AllowUserInteraction], animations: { () in
            self.innerView.layer.transform = CATransform3DMakeScale(self.scale, self.scale, 1)
            }, completion: nil)
    }
    
    func buttonCancel() {
        self.layoutSubviewsEnabled = false
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: [UIViewAnimationOptions.CurveEaseOut, UIViewAnimationOptions.AllowUserInteraction], animations: { () in
            self.innerView.layer.transform = CATransform3DIdentity
            }, completion: nil)
    }
    
    func buttonClick() {
        self.layoutSubviewsEnabled = false
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: [UIViewAnimationOptions.CurveEaseOut, UIViewAnimationOptions.AllowUserInteraction], animations: { () in
            self.innerView.layer.transform = CATransform3DIdentity
            }, completion: nil)
    }
}
