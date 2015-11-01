import UIKit

//This contains the credit-card form that is displayed if the user hits the 'credit_card' payment
//button on setup
class AcceptOnPriceTitleView: UIView
{
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    var blurView: UIVisualEffectView!
    
    //Price label, like $4.96
    lazy var priceLabel = UILabel()
    var price: String {
        set {
            priceLabel.text = newValue
        }
        get { return priceLabel.text ?? "" }
    }
    lazy var priceBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    
    //Description that goes on the right
    lazy var descLabel = UILabel()
    var desc: String {
        set {
            descLabel.text = newValue
        }
        get { return descLabel.text ?? "" }
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
        //Blur backdrop
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        self.addSubview(blurView)
        blurView.snp_makeConstraints { make in
            make.margins.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
        
        //Add price label
        blurView.contentView.addSubview(priceBlurView)
        priceBlurView.snp_makeConstraints { make in
            make.width.equalTo(blurView.snp_height)
            make.height.equalTo(blurView.snp_height)
            make.right.equalTo(blurView.snp_right)
            make.top.equalTo(blurView.snp_top)
            return
        }
        priceBlurView.contentView.addSubview(priceLabel)
        priceLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 20)
        priceLabel.textColor = UIColor.whiteColor()
        priceLabel.textAlignment = NSTextAlignment.Center
        priceLabel.snp_makeConstraints { make in
            make.margins.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
        
        //Add description label
        blurView.contentView.addSubview(descLabel)
        descLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 20)
        descLabel.textColor = UIColor.whiteColor()
        descLabel.snp_makeConstraints { make in
            make.left.equalTo(blurView.snp_left).offset(10)
            make.top.equalTo(blurView.snp_top)
            make.bottom.equalTo(blurView.snp_bottom)
            make.right.equalTo(priceLabel.snp_left).offset(-20)
            return
        }
        
        //Hide until we animate in
        self.alpha = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
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
    func animateIn() {
        self.alpha = 1
        self.blurView.layer.transform = CATransform3DMakeTranslation(0, self.bounds.size.height, 0)
        
        UIView.animateWithDuration(0.7, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.blurView.layer.transform = CATransform3DIdentity
            }, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Signal / Action Handlers
    //-----------------------------------------------------------------------------------------------------
    
    //-----------------------------------------------------------------------------------------------------
    //External / Delegate Handlers
    //-----------------------------------------------------------------------------------------------------
}
