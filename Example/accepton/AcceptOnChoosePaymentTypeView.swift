import UIKit
import accepton

protocol AcceptOnChoosePaymentTypeViewDelegate {
    func choosePaymentTypeWasClicked(name: String)
}

class AcceptOnChoosePaymentTypeView: UIView
{
    //-----------------------------------------------------------------------------------------------------
    //Property
    //-----------------------------------------------------------------------------------------------------
    //The listing of payment types, e.g. 'paypal' that should be displayed
    //as clickable buttons
    var _availablePaymentTypes: [String] = []
    var availablePaymentTypes: [String] {
        set {
            
        }
        
        get {
            return _availablePaymentTypes
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