import UIKit

class AcceptOnFillOutRemainingViewCell: UIView
{
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    var countLabel = UILabel()
    
    var content = UIView()
    
    var viewToCenterCountOn: UIView! {
        didSet {
//            countLabel.snp_remakeConstraints {
//                $0.left.equalTo(0)
//                $0.centerY.equalTo(viewToCenterCountOn!.snp_centerY)
//                $0.width.equalTo(40)
//                $0.height.equalTo(40)
//                return
//            }
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
//        self.addSubview(countLabel)
//
//        countLabel.textAlignment = .Center
//        countLabel.font = UIFont(name: "HelveticaNeue-Light", size: 14)
//        countLabel.textColor = UIColor(white: 0.15, alpha: 1)
//        countLabel.backgroundColor = UIColor(white: 0.95, alpha: 1)
//        countLabel.clipsToBounds = true
        
        self.addSubview(content)
        content.snp_makeConstraints {
            $0.left.equalTo(0)
            $0.top.bottom.right.equalTo(0)
            return
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        countLabel.layer.cornerRadius = countLabel.bounds.size.height/2
    }
    
    var constraintsWereUpdated = false
    override func updateConstraints() {
        super.updateConstraints()
        
        //Only run custom constraints once
        if (constraintsWereUpdated) { return }
        constraintsWereUpdated = true
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Animation Helpers
    //-----------------------------------------------------------------------------------------------------
    
    //-----------------------------------------------------------------------------------------------------
    //Signal / Action Handlers
    //-----------------------------------------------------------------------------------------------------
    
    //-----------------------------------------------------------------------------------------------------
    //External / Delegate Handlers
    //-----------------------------------------------------------------------------------------------------
}
