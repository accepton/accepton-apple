import UIKit

//Contains the lock & logo at the bottom of the payment
class AcceptOnFooterView: UIView
{
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    var blurView: UIVisualEffectView!
    
    lazy var securedByView = UIView()
    lazy var lockImageView = UIImageView(image: AcceptOnBundle.UIImageNamed("lock.png"))
        lazy var securedLabel = UILabel()
    
    lazy var poweredByAcceptonView = UIView()
        lazy var poweredByLabel = UILabel()
        lazy var acceptonLogo = UIImageView(image: AcceptOnBundle.UIImageNamed("accepton.png")?.imageWithColor(UIColor.whiteColor()))
    
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
        
        //Create "powered by accepton XXX with logo"
        self.addSubview(poweredByAcceptonView)
        poweredByAcceptonView.snp_makeConstraints { make in
            make.height.equalTo(self.snp_height)
            make.left.equalTo(self.snp_left).offset(7)
            make.top.equalTo(self.snp_top)
            return
        }
        self.poweredByAcceptonView.addSubview(poweredByLabel)
        self.poweredByAcceptonView.addSubview(acceptonLogo)
        
        //Add "powered by accepton" text
        poweredByLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 9)
        poweredByLabel.text = "Payments Powered by"
        poweredByLabel.textColor = UIColor.whiteColor()
        poweredByLabel.snp_makeConstraints { make in
            make.top.equalTo(self.poweredByAcceptonView.snp_top)
            make.left.equalTo(self.poweredByAcceptonView.snp_left)
            make.right.equalTo(self.acceptonLogo.snp_left).offset(-3)
            make.bottom.equalTo(self.poweredByAcceptonView.snp_bottom)
            return
        }
    
        //Add logo to 'powered by accepton'
        acceptonLogo.snp_makeConstraints { make in
            make.top.equalTo(self.poweredByAcceptonView.snp_top)
            make.bottom.equalTo(self.poweredByAcceptonView.snp_bottom)
            make.right.equalTo(self.poweredByAcceptonView.snp_right)
            make.width.equalTo(self.poweredByAcceptonView.snp_height).multipliedBy(1.5)
            return
        }
        acceptonLogo.contentMode = UIViewContentMode.ScaleAspectFit
        
        //Created secured by view
        self.addSubview(securedByView)
        securedByView.snp_makeConstraints { make in
            make.top.equalTo(self.snp_top)
            make.bottom.equalTo(self.snp_bottom)

            make.right.equalTo(self.snp_right).offset(-7)
            return
        }
        securedByView.addSubview(lockImageView)
        securedByView.addSubview(securedLabel)
        
        //Add lock logo
        lockImageView.snp_makeConstraints { make in
            make.width.equalTo(20)
            make.left.equalTo(self.securedByView.snp_left)
            make.right.equalTo(self.securedLabel.snp_left)
            make.centerY.equalTo(self.securedByView.snp_centerY)
            make.height.equalTo(self.securedByView.snp_height).multipliedBy(0.5)
            return
        }
        lockImageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        //Add the "secured by 256-bit..."
        securedLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 9)
        securedLabel.text = "256-bit SSL"
        securedLabel.textColor = UIColor.whiteColor()
        securedLabel.snp_makeConstraints { make in
            make.top.equalTo(self.securedByView.snp_top)
            make.right.equalTo(self.securedByView.snp_right)
            make.bottom.equalTo(self.securedByView.snp_bottom)
            return
        }
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
    
    //-----------------------------------------------------------------------------------------------------
    //Signal / Action Handlers
    //-----------------------------------------------------------------------------------------------------
    
    //-----------------------------------------------------------------------------------------------------
    //External / Delegate Handlers
    //-----------------------------------------------------------------------------------------------------
}
