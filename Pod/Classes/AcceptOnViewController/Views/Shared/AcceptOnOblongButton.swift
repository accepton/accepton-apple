import UIKit

//This creates an oblong (slot) shaped button
class AcceptOnOblongButton : UIButton {
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    var disabled: Bool = false {
        didSet {
            if disabled {
                self.userInteractionEnabled = false
                self.backgroundColor = UIColor(white: 0.8, alpha: 1)
            } else {
                self.userInteractionEnabled = true
                self.backgroundColor = color
            }
        }
    }
    
    var color: UIColor? {
        didSet {
            self.backgroundColor = color
        }
    }
    
    var title: String? {
        get { return label.text }
        set { label.text = newValue }
    }
    
    let label = UILabel()
    
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
        //Make sure the rounding is shown
        self.layer.masksToBounds = true
        
        self.addSubview(label)
        label.snp_makeConstraints {
            $0.top.left.right.bottom.equalTo(0)
            return
        }
        label.font = UIFont(name: "HelveticaNeue-Light", size: 17)
        label.textColor = UIColor.whiteColor()
        label.textAlignment = .Center
        
        //Bind event handlers for the button
        self.addTarget(self, action: "buttonDidClick", forControlEvents: UIControlEvents.TouchUpInside)
        self.addTarget(self, action: "buttonDidTouchDown", forControlEvents: [UIControlEvents.TouchDown, UIControlEvents.TouchDragEnter])
        self.addTarget(self, action: "buttonDidCancel", forControlEvents: [UIControlEvents.TouchCancel, UIControlEvents.TouchDragExit])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //Make it oblong (slot) shapped
        self.layer.cornerRadius = self.bounds.size.height / 2
    }
    
    //------------------------------------------------------------------------------------------------------
    //Event Handling
    //------------------------------------------------------------------------------------------------------
    func buttonDidTouchDown() {
        self.label.alpha = 0
    }
    
    func buttonDidCancel() {
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: { () -> Void in
            self.label.alpha = 1
            }, completion: nil)
    }
    
    func buttonDidClick() {
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: { () -> Void in
            self.label.alpha = 1
            }, completion: nil)
    }
}

