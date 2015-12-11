import UIKit

protocol AcceptOnFillOutAddressViewDelegate: class {
    func presentAddressPickerView(view: UIView)
    func dismissAddressPickerView(view: UIView)
    
    var api: AcceptOnAPI { get }
}

enum AcceptOnFillOutAddressViewCaseResponses {
    case ToggleEnabled
}

//This contains the credit-card form that is displayed if the user hits the 'credit_card' payment
//button on setup
class AcceptOnFillOutAddressView: UIView, AcceptOnFillOutRemainingSubForm, AcceptOnAddressPickerViewDelegate
{
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    weak var delegate: AcceptOnFillOutRemainingSubFormDelegate?
    
    //Is this form ready? The submit button gets disabled if this form isn't
    //Needed because some forms need to fetch information like the address fields
    //even after user selects an address because of the way google's API's work
    var readyStatus: Bool = false
    
    //What this sub-form represents like an address
    var value: Any? {
        //Usually for matches address
        if hasToggle {
            if toggleSwitch.on {
                return AcceptOnFillOutAddressViewCaseResponses.ToggleEnabled
            } else {
                return self.addressBox.address
            }
        } else {
            return self.addressBox.address
        }
    }
    
    //Label as address & billing need to say something different
    let label = UILabel()
    var title: String? {
        get { return label.text }
        set { label.text = newValue }
    }
    
    var addressBoxButton = AcceptOnPopButton()
    var addressBox = AcceptOnAddressPreview()
    
    var toggleView = UIView()
    var toggleLabel = UILabel()
    var toggleSwitch = UISwitch()
    
    
    var hasToggle: Bool = false
    
    var viewToCenterCountOn: UIView {
        if hasToggle {
            return toggleView
        } else {
            return self.addressBox
        }
    }
    
    weak var addressDelegate: AcceptOnFillOutAddressViewDelegate!
    
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
        defaultInit()
    }
    
    func defaultInit() {
        //Toggle view is optional, usually for 'same as billing' address
        self.addSubview(toggleView)
        toggleView.snp_makeConstraints {
            $0.top.equalTo(0)
            $0.centerX.equalTo(0)
            $0.height.equalTo(70)
            return
        }
        toggleView.alpha = 0
        toggleView.addSubview(toggleLabel)
        
        toggleLabel.snp_makeConstraints {
            $0.left.equalTo(0)
            $0.centerY.equalTo(0)
            return
        }
        toggleLabel.font = UIFont(name: "HelveticaNeue-Light", size: 10)
        toggleLabel.textColor = UIColor(white: 0.18, alpha: 1)
        toggleLabel.adjustsFontSizeToFitWidth = true
        toggleLabel.minimumScaleFactor = 0.5
        
        toggleView.addSubview(toggleSwitch)
        toggleSwitch.snp_makeConstraints {
            $0.left.equalTo(toggleLabel.snp_right).offset(10)
            $0.right.equalTo(0)
            $0.centerY.equalTo(0)
            return
        }
        toggleSwitch.addTarget(self, action: "toggleChanged", forControlEvents: UIControlEvents.ValueChanged)
        toggleSwitch.on = true
        
        self.addSubview(label)
        label.snp_makeConstraints {
            $0.centerX.equalTo(0)
            $0.top.equalTo(self.toggleView.snp_bottom).offset(-50)
            return
        }
        label.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        label.textColor = UIColor(white: 0.75, alpha: 1)
        label.textAlignment = .Center
        
        self.addSubview(addressBoxButton)
        addressBoxButton.snp_makeConstraints {
            $0.top.equalTo(self.label.snp_bottom).offset(4)
            $0.bottom.equalTo(0)
            $0.centerX.equalTo(0)
            return
        }
        addressBoxButton.addSubview(addressBox)
        addressBoxButton.innerView = addressBox
        addressBox.userInteractionEnabled = false
        addressBox.snp_makeConstraints {
            $0.top.left.right.bottom.equalTo(0)
            return
        }
        
        addressBoxButton.addTarget(self, action: "buttonClicked", forControlEvents: .TouchUpInside)
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
    //Need to load actual address from google places API and this takes time
    func toggleLoadingAnimation(show: Bool) {
        self.addressBox.toggleLoadingAnimation(show)
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Signal / Action Handlers
    //-----------------------------------------------------------------------------------------------------
    func toggleChanged() {
        let toggled = self.toggleSwitch.on
        
        //Don't enable same shipping
        if !toggled {
            readyStatus = false
            self.addressBox.address = nil
            self.delegate?.subFormDidUpdateReadyStatus(self)
            var transform = CATransform3DMakeScale(0.9, 0.9, 1)
            transform = CATransform3DTranslate(transform, 0, 80, 0)
            self.label.layer.transform = transform
            self.label.alpha = 0
            self.addressBox.alpha = 0
            self.addressBox.layer.transform = transform
            UIView.animateWithDuration(0.77, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.CurveEaseOut, .BeginFromCurrentState], animations: {
                self.label.alpha = 1
                self.label.layer.transform = CATransform3DIdentity
            }, completion: nil)
            
            UIView.animateWithDuration(0.77, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: {
                self.addressBox.alpha = 1
                self.addressBox.layer.transform = CATransform3DIdentity
                }, completion: nil)
        } else {
            self.readyStatus = true
            self.delegate?.subFormDidUpdateReadyStatus(self)
            
            var transform = CATransform3DMakeScale(0.9, 0.9, 1)
            transform = CATransform3DTranslate(transform, 0, 300, 0)
            transform = CATransform3DRotate(transform, CGFloat(M_PI)/30, 0, 0, 1)
            UIView.animateWithDuration(0.57, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: {
                self.label.layer.transform = transform
                self.label.alpha = 0
                }, completion: { comp in
//                    self.label.alpha = 0
//                    self.addressBox.alpha = 0
            })
            
            UIView.animateWithDuration(0.57, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: {
                self.addressBox.alpha = 0
                self.addressBox.layer.transform = transform
                
                }, completion: nil)
        }
    }
    
    func buttonClicked() {
        let picker = AcceptOnAddressPickerView()
        picker.delegate = self
        self.addressDelegate?.presentAddressPickerView(picker)
    }
    
    //-----------------------------------------------------------------------------------------------------
    //External / Delegate Handlers
    //-----------------------------------------------------------------------------------------------------
    func showToggleWithText(text: String) {
        self.hasToggle = true
        self.toggleLabel.text = text
        toggleView.alpha = 1
        
        label.snp_remakeConstraints {
            $0.centerX.equalTo(0)
            $0.top.equalTo(self.toggleView.snp_bottom)
            return
        }
        self.layoutSubviews()
        
        addressBox.alpha = 0
        label.alpha = 0
        self.readyStatus = true
        self.delegate?.subFormDidUpdateReadyStatus(self)
    }
    
    func setSuggestedAddress(address: AcceptOnAPIAddress?) {
        if let address = address where address.isFullyQualified {
            self.addressBox.address = address
            self.readyStatus = true
            self.delegate?.subFormDidUpdateReadyStatus(self)
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //AcceptOnFillOutRemainingSubFormDelegate
    //-----------------------------------------------------------------------------------------------------
    
    //-----------------------------------------------------------------------------------------------------
    //AcceptOnAddressPickerViewDelegate
    //-----------------------------------------------------------------------------------------------------
    func addressWasSelected(picker: AcceptOnAddressPickerView, withTag tag: String, withExtraLineInformation extra: String?) {
        self.addressDelegate?.dismissAddressPickerView(picker)
        self.readyStatus = false
        self.delegate?.subFormDidUpdateReadyStatus(self)
        let placeId = tag
        
        toggleLoadingAnimation(true)
        self.addressDelegate.api.convertPlaceIdToAddress(tag) { (var addr, err) in
            if !addr!.isFullyQualified {
                let alert = UIAlertView()
                alert.title = "Uh Oh"
                alert.message = "Your address was not specific enough. Please try re-entering it"
                alert.addButtonWithTitle("Understood")
                alert.show()
                self.addressBox.address = nil
                self.toggleLoadingAnimation(false)
                return
            }
            
            //User entered information like apartment #, PO Box, etc.
            addr!.line2 = extra
            
            self.readyStatus = true
            self.delegate?.subFormDidUpdateReadyStatus(self)
            self.addressBox.address = addr
            self.toggleLoadingAnimation(false)
        }
    }
    
    func addressWasNotSelected(picker: AcceptOnAddressPickerView) {
        self.addressDelegate?.dismissAddressPickerView(picker)
    }
    
    func addressInputDidUpdate(picker: AcceptOnAddressPickerView, withText text: String) {
        var address: AcceptOnAPIAddress?

        self.addressDelegate.api.autoCompleteAddress(text) { _addresses, err in
            var addresses: [(description: String, tag: String)] = []
            for e in _addresses! {
                addresses.append((description: e.description, tag: e.placeId))
            }
            picker.updateAddressList(addresses)
        }
    }
    
    
}
