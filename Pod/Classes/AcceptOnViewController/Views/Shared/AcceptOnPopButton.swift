import UIKit

//This is a button that goes 'pop' on touch-down.  Used for back buttons, exit buttons, etc.
class AcceptOnPopButton: UIButton {
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    //The amount of space around the innerView
    var padding: CGFloat = 0
    
    var layoutSubviewsIsDisabled: Bool = false
    
    //View to animate, should be added by an external view right after initialization. Should not
    //have any constraints installed on it
    var innerView: UIView!
    
    @IBInspectable var scale: CGFloat = 0.8
    
    //-----------------------------------------------------------------------------------------------------
    //Constructors, Initializers, and UIView lifecycle
    //-----------------------------------------------------------------------------------------------------
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        viewDidLoad()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewDidLoad()
    }
    
    func viewDidLoad() {
        //Bind event handlers for the button
        self.addTarget(self, action: "buttonDidClick", forControlEvents: UIControlEvents.TouchUpInside)
        self.addTarget(self, action: "buttonDidTouchDown", forControlEvents: [UIControlEvents.TouchDown, UIControlEvents.TouchDragEnter])
        self.addTarget(self, action: "buttonDidCancel", forControlEvents: [UIControlEvents.TouchCancel, UIControlEvents.TouchDragExit])
    }
    
    //------------------------------------------------------------------------------------------------------
    //View Rendering
    //------------------------------------------------------------------------------------------------------
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //Ensure our inner-view is in the correct location
        if (self.layoutSubviewsIsDisabled) { return }
        self.innerView.frame = CGRectInset(self.bounds, self.padding, self.padding)
    }
    
    //------------------------------------------------------------------------------------------------------
    //Event Handling
    //------------------------------------------------------------------------------------------------------
    func buttonDidTouchDown() {
        self.layoutSubviewsIsDisabled = true
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: [UIViewAnimationOptions.CurveEaseOut, UIViewAnimationOptions.AllowUserInteraction], animations: { () in
            self.innerView.layer.transform = CATransform3DMakeScale(self.scale, self.scale, 1)
            }, completion: {res in
        })
    }
    
    func buttonDidCancel() {
        self.layoutSubviewsIsDisabled = true
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: [UIViewAnimationOptions.CurveEaseOut, UIViewAnimationOptions.AllowUserInteraction], animations: { () in
            self.innerView.layer.transform = CATransform3DIdentity
            }, completion: nil)
    }
    
    func buttonDidClick() {
        self.layoutSubviewsIsDisabled = true
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: [UIViewAnimationOptions.CurveEaseOut, UIViewAnimationOptions.AllowUserInteraction], animations: { () in
            self.innerView.layer.transform = CATransform3DIdentity
            }, completion: nil)
    }
}
