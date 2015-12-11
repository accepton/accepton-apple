import UIKit

//This view supports showing an address or just gray boxes where the address fields would go
class AcceptOnAddressPreview: UIView
{
    //-----------------------------------------------------------------------------------------------------
    //Constants
    //-----------------------------------------------------------------------------------------------------
    let fieldHeight = 20
    let fieldSpacing = 5
    
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    let line1Field = AcceptOnAddressPreviewLineLabel()
    let line2Field = AcceptOnAddressPreviewLineLabel()
    let cityField = AcceptOnAddressPreviewLineLabel()
    let stateField = AcceptOnAddressPreviewLineLabel()
    let zipField = AcceptOnAddressPreviewLineLabel()

    var activeFields: [UILabel] {
        if line2IsActive {
            return [line1Field, line2Field, cityField, stateField, zipField]
        } else {
            return [line1Field, cityField, stateField, zipField]
        }
    }
    
    var fields: [UILabel] {
        return [line1Field, line2Field, cityField, stateField, zipField]
    }
    
    var content = UIView()
    
    //Line2 is optional
    var line2HeightConstraint: Constraint!
    var line2TopOffset: Constraint!
    var line2IsActive: Bool = false {
        didSet {
            if line2IsActive {
                line2HeightConstraint.updateOffset(fieldHeight)
                line2TopOffset.updateOffset(fieldSpacing)
            } else {
                line2HeightConstraint.updateOffset(0)
                line2TopOffset.updateOffset(0)
            }
        }
    }
    
    var address: AcceptOnAPIAddress? {
        didSet {
            if let address = address {
                line1Field.text = address.line1
                cityField.text = address.city
                stateField.text = address.region
                zipField.text = address.postalCode
                
                if let line2 = address.line2 {
                    line2IsActive = true
                    line2Field.text = line2
                } else {
                    line2IsActive = false
                    line2Field.text = nil
                }
            } else {
                line1Field.text = ""
                cityField.text = ""
                stateField.text = ""
                zipField.text = ""
                line2IsActive = false
            }
        }
    }
    
    var loadingSpinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    
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
        self.backgroundColor = UIColor(white: 0.9, alpha: 1)
        
        //Centers all fields
        self.addSubview(content)
        content.snp_makeConstraints {
            $0.center.equalTo(0)
            $0.width.equalTo(200)
            $0.top.equalTo(12)
            $0.bottom.equalTo(-12)
            $0.left.equalTo(12)
            $0.right.equalTo(-12)
            return
        }
        
        content.addSubview(line1Field)
        line1Field.snp_makeConstraints {
            $0.top.equalTo(0)
            $0.left.right.equalTo(0)
            $0.height.equalTo(self.fieldHeight)
            return
        }
        line1Field.backgroundColor = UIColor(white: 0.8, alpha: 1)
        line1Field.clipsToBounds = true
        
        //Optional
        content.addSubview(line2Field)
        line2Field.snp_makeConstraints {
            self.line2TopOffset = $0.top.equalTo(line1Field.snp_bottom).offset(0).constraint
            $0.left.right.equalTo(0)
            self.line2HeightConstraint = $0.height.equalTo(0).constraint
            return
        }
        line2Field.backgroundColor = UIColor(white: 0.8, alpha: 1)
        line2Field.clipsToBounds = true
        
        content.addSubview(cityField)
        cityField.snp_makeConstraints {
            $0.top.equalTo(self.line2Field.snp_bottom).offset(self.fieldSpacing)
            $0.left.equalTo(0)
            $0.height.equalTo(line1Field.snp_height)
            $0.width.equalTo(60)
            return
        }
        cityField.backgroundColor = UIColor(white: 0.8, alpha: 1)
        cityField.clipsToBounds = true
        cityField.minimumScaleFactor = 0.5
        cityField.adjustsFontSizeToFitWidth = true

        content.addSubview(stateField)
        stateField.snp_makeConstraints {
            $0.top.equalTo(self.cityField.snp_top)
            $0.left.equalTo(self.cityField.snp_right).offset(self.fieldSpacing)
            $0.height.equalTo(line1Field.snp_height)
            $0.bottom.equalTo(cityField.snp_bottom)
            $0.width.equalTo(40)
            return
        }
        stateField.backgroundColor = UIColor(white: 0.8, alpha: 1)
        stateField.clipsToBounds = true
        
        content.addSubview(zipField)
        zipField.snp_makeConstraints {
            $0.top.equalTo(stateField.snp_bottom).offset(self.fieldSpacing)
            $0.left.equalTo(0)
            $0.width.equalTo(80)
            $0.height.equalTo(line1Field.snp_height)
            $0.bottom.equalTo(0)
            return
        }
        zipField.backgroundColor = UIColor(white: 0.8, alpha: 1)
        zipField.clipsToBounds = true
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 2
        
        for e in fields {
            e.textColor = UIColor(white: 0.15, alpha: 1)
            e.font = UIFont(name: "HelveticaNeue-Light", size: 12)
        }
        
        
        //Add loading spinner
        self.addSubview(loadingSpinner)
        loadingSpinner.snp_makeConstraints {
            $0.center.equalTo(self.snp_center)
            return
        }
        loadingSpinner.alpha = 0
        loadingSpinner.startAnimating()
        loadingSpinner.color = UIColor(white: 0.15, alpha: 1)
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
    func toggleLoadingAnimation(show: Bool) {
        if show {
            for e in activeFields {
                e.alpha = 0
                
                loadingSpinner.alpha = 1
            }
        } else {
            for (i, e) in activeFields.enumerate() {
                var transform = CATransform3DMakeScale(0.8, 0.8, 1)
                transform = CATransform3DTranslate(transform, 0, 40, 0)
                e.layer.transform = transform
                
                UIView.animateWithDuration(0.77, delay: NSTimeInterval(i)*0.05, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: {
                    e.layer.transform = CATransform3DIdentity
                    e.alpha = 1
                    }, completion: nil)
            }
            
            loadingSpinner.alpha = 0
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Signal / Action Handlers
    //-----------------------------------------------------------------------------------------------------
    
    //-----------------------------------------------------------------------------------------------------
    //External / Delegate Handlers
    //-----------------------------------------------------------------------------------------------------
}

class AcceptOnAddressPreviewLineLabel: UILabel {
    override func drawTextInRect(rect: CGRect) {
        let insets = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
}
