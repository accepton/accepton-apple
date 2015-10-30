import UIKit
import accepton

@objc protocol AcceptOnNavigationBarDelegate {
}

//'choose your payment type' view backed by the XIB named AcceptOnChoosePaymentTypeView
//The actual view that has the animated buttons is called AcceptOnChoosePaymentTypeSelectorView
class AcceptOnNavigationBar: UIView
{
    //-----------------------------------------------------------------------------------------------------
    //Property
    //-----------------------------------------------------------------------------------------------------
    var backButton: AcceptOnPopButton!
    
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
    
    func defaultInit() {
//        self.backButton = AcceptOnPopButton()
//        self.backButton.image = UIImage(named: "back_arrow")!
//        self.addSubview(self.backButton)
//        backButton.snp_makeConstraints { make in
//            make.width.equalTo(26)
//            make.height.equalTo(26)
//            make.left.equalTo(self.snp_left).offset(25)
//            make.centerY.equalTo(self.snp_centerY)
//            return
//        }
    }
}

