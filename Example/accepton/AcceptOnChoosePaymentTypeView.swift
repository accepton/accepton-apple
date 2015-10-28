import UIKit
import accepton

protocol AcceptOnChoosePaymentTypeViewDelegate {
    func choosePaymentTypeWasClicked(name: String)
}

//'choose your payment type' view backed by the XIB named AcceptOnChoosePaymentTypeView
//The actual view that has the animated buttons is called AcceptOnChoosePaymentTypeSelectorView
class AcceptOnChoosePaymentTypeView: UIView
{
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
    
    func defaultInit() {
        let nib = UINib(nibName: "AcceptOnChoosePaymentTypeView", bundle: NSBundle(forClass: self.dynamicType))
        let nibInstance = nib.instantiateWithOwner(self, options: nil)
        let view = nibInstance[0] as! UIView
        
        self.addSubview(view)
        view.snp_makeConstraints { make in
            make.edges.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
            return
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func updateConstraints() {
        super.updateConstraints()
    }
}