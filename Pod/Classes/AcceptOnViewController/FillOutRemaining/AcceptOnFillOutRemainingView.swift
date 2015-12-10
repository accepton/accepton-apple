import UIKit

//Values indicate order, lower numbers appear first
public enum AcceptOnFillOutRemainingOption: Int {
    case BillingAddress = 1
    case ShippingAddress = 0
}

public protocol AcceptOnFillOutRemainingSubForm {
    weak var delegate: AcceptOnFillOutRemainingSubFormDelegate? { get }
    
    //Is this form ready? The submit button gets disabled if this form isn't
    //Needed because some forms need to fetch information like the address fields
    //even after user selects an address because of the way google's API's work
    var readyStatus: Bool { get }
    
    //What this sub-form represents like an address
    var value: Any? { get }
    
    //Return the view that you want to use as a centerY for the count (similar to alignment rect)
    var viewToCenterCountOn: UIView { get }
}

public protocol AcceptOnFillOutRemainingSubFormDelegate: class {
    //Did this form change it's ready status?
    func subFormDidUpdateReadyStatus(subForm: AcceptOnFillOutRemainingSubForm)
}

public protocol AcceptOnFillOutRemainingViewDelegate: class {
    var api: AcceptOnAPI { get }
    
    func fillOutRemainingDidProvideInformation(info: [AcceptOnFillOutRemainingOption:Any?])
    func fillOutRemainingDidCancel()
}

//Fill out remaining form information like shipping & billing
public class AcceptOnFillOutRemainingView: UIView, AcceptOnFillOutAddressViewDelegate, AcceptOnFillOutRemainingSubFormDelegate
{
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    //Contains all the forms
    let content = UIScrollView()
    var subForms: [(option: AcceptOnFillOutRemainingOption, form: AcceptOnFillOutRemainingSubForm)] = []
    var optionToSubForm: [AcceptOnFillOutRemainingOption:AcceptOnFillOutRemainingSubForm] {
        get {
            var output: [AcceptOnFillOutRemainingOption:AcceptOnFillOutRemainingSubForm] = [:]
            for e in subForms {
                output[e.option] = e.form
            }
            
            return output
        }
    }
    
    var api: AcceptOnAPI {
        return delegate!.api
    }
    
    var submitButtonArea = UIView()
    var submitButton = AcceptOnOblongButton()
    
    var remainingOptions: [AcceptOnFillOutRemainingOption]!
    
    //Text at top
    let titleLabel = UILabel()
    
    public weak var delegate: AcceptOnFillOutRemainingViewDelegate!
    
    //-----------------------------------------------------------------------------------------------------
    //Constructors, Initializers, and UIView lifecycle
    //-----------------------------------------------------------------------------------------------------
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)!
    }
    
    //Give a list of things that still need to be filled out
    public convenience init(var remainingOptions: [AcceptOnFillOutRemainingOption]) {
        self.init(frame: CGRectZero)
        
        
        remainingOptions.sortInPlace { (a, b) -> Bool in
            a.rawValue < b.rawValue
        }
        self.remainingOptions = remainingOptions
        self.defaultInit()
    }
    
    public func defaultInit() {
        
        //Add title label
        self.addSubview(titleLabel)
        titleLabel.text = "Just a few last questions"
        titleLabel.snp_makeConstraints {
            $0.left.right.equalTo(0)
            $0.top.equalTo(30)
            $0.height.equalTo(50)
            return
        }
        titleLabel.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        titleLabel.textColor = UIColor(white: 0.15, alpha: 1)
        titleLabel.textAlignment = .Center
        
        //Back arrow
        let backButton = AcceptOnPopButton()
        self.addSubview(backButton)
        var backArrowImage = AcceptOnBundle.UIImageNamed("back_arrow")
        backArrowImage = backArrowImage?.imageWithColor(UIColor(white: 0.45, alpha: 1))
        let backArrowImageView = UIImageView(image: backArrowImage)
        backButton.addSubview(backArrowImageView)
        backButton.innerView = backArrowImageView
        backButton.snp_makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(40)
            make.left.equalTo(self.snp_left).offset(20)
            make.centerY.equalTo(self.titleLabel.snp_centerY)
            return
        }
        backButton.padding = 13
        backButton.addTarget(self, action: "backWasClicked", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.addSubview(submitButtonArea)
        submitButtonArea.snp_makeConstraints {
            $0.bottom.left.right.equalTo(0)
            $0.height.equalTo(80)
            return
        }
        
        //Add button
        self.submitButtonArea.addSubview(submitButton)
        submitButton.snp_makeConstraints {
            $0.center.equalTo(0)
            $0.width.equalTo(200)
            $0.height.equalTo(45)
        }
        submitButton.color = UIColor.FlatGreen
        submitButton.title = "Submit"
        submitButton.disabled = true
        submitButton.addTarget(self, action: "submitWasClicked", forControlEvents: .TouchUpInside)
        
        self.addSubview(content)
        content.snp_makeConstraints {
            $0.left.right.equalTo(0)
            $0.bottom.equalTo(self.submitButtonArea.snp_top)
            $0.top.equalTo(self.titleLabel.snp_bottom)
            return
        }
        content.delaysContentTouches = false
        
        //Add options
        for e in remainingOptions {
            addSubForm(e, form: formForOption(e))
        }
        self.finishedAddingSubForms()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    var constraintsWereUpdated = false
    public override func updateConstraints() {
        super.updateConstraints()
        
        //Only run custom constraints once
        if (constraintsWereUpdated) { return }
        constraintsWereUpdated = true
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Adding / Removing sub-form elements
    //-----------------------------------------------------------------------------------------------------
    public func addSubForm(option: AcceptOnFillOutRemainingOption, form: AcceptOnFillOutRemainingSubForm) {
        let cell = AcceptOnFillOutRemainingViewCell()
        cell.countLabel.text = "\(subForms.count)"
        let view = form as! UIView
        cell.content.addSubview(view)
        cell.viewToCenterCountOn = form.viewToCenterCountOn
        content.addSubview(cell)
        view.snp_makeConstraints {
            $0.top.bottom.left.right.equalTo(0)
            return
        }
        
        let lastView = subForms.last?.form as? UIView
        
//        content.addSubview(view)
        cell.snp_makeConstraints {
            if subForms.count == 0 {
                $0.top.equalTo(0)
            } else {
                $0.top.equalTo(lastView!.snp_bottom).offset(0)
            }
            
            $0.width.equalTo(content.snp_width).offset(-20)
            $0.centerX.equalTo(0)
            return
        }
        
        subForms.append(option: option, form: form)
    }
    
    //Call this when you are done adding sub-forms
    public func finishedAddingSubForms() {
        let lastView = subForms.last?.form as? UIView
        if let lastView = lastView {
            lastView.snp_makeConstraints {
                $0.bottom.equalTo(0)
                return
            }
        }
    }
    
    func formForOption(option: AcceptOnFillOutRemainingOption) -> AcceptOnFillOutRemainingSubForm {
        if option == .BillingAddress {
            let address = AcceptOnFillOutAddressView()
            address.addressDelegate = self
            address.delegate = self
            address.title = "Billing Address"
            
            //If there is a billing address, activate the 'same' toggle switch
            if self.remainingOptions.filter({$0 == .ShippingAddress}).first != nil {
                address.showToggleWithText("Billing address is same as shipping")
            }
            
            return address
        } else if option == .ShippingAddress {
            let address = AcceptOnFillOutAddressView()
            address.delegate = self
            address.addressDelegate = self
            address.title = "Shipping Address"
            return address
        }
        return AcceptOnFillOutAddressView()
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Animation Helpers
    //-----------------------------------------------------------------------------------------------------
    
    //-----------------------------------------------------------------------------------------------------
    //Signal / Action Handlers
    //-----------------------------------------------------------------------------------------------------
    func submitWasClicked() {
        var res: [AcceptOnFillOutRemainingOption:Any?] = [:]
        for e in self.subForms {
            res[e.option] = e.form.value
        }
        self.delegate.fillOutRemainingDidProvideInformation(res)
    }
    
    func backWasClicked() {
        self.delegate.fillOutRemainingDidCancel()
    }
    
    //-----------------------------------------------------------------------------------------------------
    //External / Delegate Handlers
    //-----------------------------------------------------------------------------------------------------
    
    //-----------------------------------------------------------------------------------------------------
    //AcceptOnFillOutAddressViewDelegate
    //-----------------------------------------------------------------------------------------------------
    func presentAddressPickerView(view: UIView) {
        self.addSubview(view)
        view.snp_makeConstraints {
            $0.top.left.bottom.right.equalTo(0)
            return
        }
        
        view.layer.transform = CATransform3DMakeTranslation(0, self.bounds.size.height, 0)
        UIView.animateWithDuration(0.7, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.CurveEaseOut, .AllowUserInteraction], animations: { () -> Void in
            view.layer.transform = CATransform3DIdentity
            }, completion: nil)
    }
    
    func dismissAddressPickerView(view: UIView) {
        UIView.animateWithDuration(0.7, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: { () -> Void in
            view.layer.transform = CATransform3DMakeTranslation(0, self.bounds.size.height, 0)
            }, completion: { res in
                view.removeFromSuperview()
        })
    }
    
    //-----------------------------------------------------------------------------------------------------
    //AcceptOnFillOutSubFormDelegate
    //-----------------------------------------------------------------------------------------------------
    public func subFormDidUpdateReadyStatus(subForm: AcceptOnFillOutRemainingSubForm) {
        var readyStatus = true
        for e in subForms {
            if e.form.readyStatus == false {
                readyStatus = false
                break
            }
        }
        
        if readyStatus {
            self.submitButton.disabled = false
        } else {
            self.submitButton.disabled = true
        }
    }
}
