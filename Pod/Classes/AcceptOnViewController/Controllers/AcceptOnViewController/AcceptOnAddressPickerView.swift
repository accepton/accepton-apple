import UIKit
import SnapKit

public protocol AcceptOnAddressPickerViewDelegate: class {
    //The current address the user has typed in, assume it's blank at the start,
    //you should make a call out to your server and then call back the updateAddressList
    //function
    func addressInputDidUpdate(picker: AcceptOnAddressPickerView, withText text: String)
    
    //The user selected an address with the tag and optional extra information like PO Box
    func addressWasSelected(picker: AcceptOnAddressPickerView, withTag tag: String, withExtraLineInformation extra: String?)
    
    //Exit was clicked
    func addressWasNotSelected(picker: AcceptOnAddressPickerView)
}

//This view allows the user to select one address by typing in a partial address
public class AcceptOnAddressPickerView: UIView, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, AddressExtraLineQuestionViewDelegate
{
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    //Text box at top
    let inputText = UITextField()
    
    //Table view of options
    let selectionTable = UITableView()
    
    //Text to show when first starting or when no results return
    let blankResultsText = UILabel()
    
    //Spinner to show when loading
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    
    //Current list of addresses that are selectable
    var addresses: [(description: String, tag: String)] = []
    
    public weak var delegate: AcceptOnAddressPickerViewDelegate!
    
    var exitButton = AcceptOnPopButton()
    
    //When the user selects an address
    var selectedAddressWithTag: String?
    
    //-----------------------------------------------------------------------------------------------------
    //Constructors, Initializers, and UIView lifecycle
    //-----------------------------------------------------------------------------------------------------
    override init(frame: CGRect) {
        super.init(frame: frame)
        defaultInit()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)!
        defaultInit()
    }
    
    convenience init() {
        self.init(frame: CGRectZero)
    }
    
    func defaultInit() {
        self.backgroundColor = UIColor.whiteColor()
        
        //exit button to exit
        self.addSubview(exitButton)
        var image = AcceptOnBundle.UIImageNamed("down_arrow")
        image = image?.imageWithColor(UIColor(white: 0.15, alpha: 1))
        let exitButtonImageView = UIImageView(image: image)
        exitButton.addSubview(exitButtonImageView)
        exitButton.innerView = exitButtonImageView
        exitButtonImageView.contentMode = .ScaleAspectFit
        exitButton.padding = 14
        exitButton.snp_makeConstraints { make in
            make.width.equalTo(self.snp_width)
            make.height.equalTo(45)
            make.centerX.equalTo(self.snp_centerX)
            make.top.equalTo(self.snp_top).offset(30)
            return
        }
        exitButton.addTarget(self, action: "exitWasClicked", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.addSubview(inputText)
        inputText.snp_makeConstraints {
            $0.top.equalTo(exitButton.snp_bottom)
            $0.left.right.equalTo(0)
            $0.height.equalTo(80)
            return
        }
        inputText.font = UIFont(name:"HelveticaNeue-Light", size: 20)
        inputText.backgroundColor = UIColor(white: 0.95, alpha: 1)
        inputText.delegate = self
        inputText.placeholder = "1 Infinite Loop, Cupertino, CA 95014"
        
        selectionTable.dataSource = self
        selectionTable.delegate = self
        self.addSubview(selectionTable)
        selectionTable.snp_makeConstraints {
            $0.top.equalTo(inputText.snp_bottom)
            $0.left.right.bottom.equalTo(0)
            return
        }
        selectionTable.alpha = 0
        
        //Center text for no results
        self.addSubview(blankResultsText)
        blankResultsText.font = UIFont(name:"HelveticaNeue-Light", size:20)
        blankResultsText.text = "Search above to see results"
        blankResultsText.snp_makeConstraints {
            $0.center.equalTo(0)
            $0.left.right.equalTo(0)
            return
        }
        blankResultsText.textAlignment = .Center
        
        //Spinner while loading
        self.addSubview(spinner)
        spinner.color = UIColor(white: 0.5, alpha: 1)
        spinner.snp_makeConstraints {
            $0.center.equalTo(0)
            $0.size.equalTo(100)
            return
        }
        spinner.startAnimating()
        spinner.alpha = 0
    }
    
    override public func layoutSubviews() {
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
    //Drawing / State helpers
    //-----------------------------------------------------------------------------------------------------
    private var extraLineQuestionView: AddressExtraLineQuestionView!
    func showExtraLineQuestion() {
        self.selectionTable.userInteractionEnabled = false
        self.inputText.userInteractionEnabled = false
        self.extraLineQuestionView = AddressExtraLineQuestionView()
        
        self.addSubview(extraLineQuestionView)
        extraLineQuestionView.delegate = self
        extraLineQuestionView.snp_makeConstraints {
            $0.top.equalTo(self.inputText)
            $0.left.bottom.right.equalTo(0)
        }
        
        extraLineQuestionView.alpha = 0
        extraLineQuestionView.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1)
        UIView.animateWithDuration(0.65, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.CurveEaseOut, .AllowUserInteraction], animations: {
            self.selectionTable.alpha = 0
            self.inputText.alpha = 0
            self.extraLineQuestionView.alpha = 1
            self.extraLineQuestionView.layer.transform = CATransform3DIdentity
            self.selectionTable.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1)
            }, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Signal / Action Handlers
    //-----------------------------------------------------------------------------------------------------
    func exitWasClicked() {
        self.delegate.addressWasNotSelected(self)
    }
    
    //-----------------------------------------------------------------------------------------------------
    //External / Delegate Handlers
    //-----------------------------------------------------------------------------------------------------
    //Update the list of available addresses
    public func updateAddressList(addresses: [(description: String, tag: String)]) {
        self.addresses = addresses
        selectionTable.alpha = 1
        spinner.alpha = 0
        selectionTable.reloadData()
        
        if addresses.count == 0 {
            blankResultsText.alpha = 1
            blankResultsText.text = "No results found"
            selectionTable.alpha = 0
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //UITableViewDelegate & UITableViewDataSource
    //-----------------------------------------------------------------------------------------------------
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addresses.count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: "default")
        cell.textLabel?.text = addresses[indexPath.row].description
        cell.textLabel?.numberOfLines = 3
        return cell
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
    
    //-----------------------------------------------------------------------------------------------------
    //UITextFieldDelegate
    //-----------------------------------------------------------------------------------------------------
    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let currentString = textField.text as NSString? else { return true }
        
        //Re-calculate string of field based on changes (we can't get the current string because it hasn't updated yet)
        let newString = currentString.stringByReplacingCharactersInRange(range, withString: string)
        
        //Expect the updateAddressList delegate to be called at after this
        spinner.alpha = 1
        blankResultsText.alpha = 0
        selectionTable.alpha = 0
        
        self.delegate.addressInputDidUpdate(self, withText: newString)
        
        return true
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedAddressWithTag = addresses[indexPath.row].tag
        self.showExtraLineQuestion()
    }
    
    //-----------------------------------------------------------------------------------------------------
    //AddressExtraLineQuestionDelegate
    //-----------------------------------------------------------------------------------------------------
    func addressExtraLineWasEntered(extra: String?) {
        self.delegate.addressWasSelected(self, withTag: selectedAddressWithTag!, withExtraLineInformation: extra)
    }
}

//This view contains the 'is this an apartment, P.O. box additional request info' that gets traded out for the table
//after the user selects an address

protocol AddressExtraLineQuestionViewDelegate: class {
    func addressExtraLineWasEntered(extra: String?)
}
class AddressExtraLineQuestionView: UIView
{
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    let label = UILabel()
    var extraTextField = UITextField()
    var submitButton = AcceptOnOblongButton()
    
    weak var delegate: AddressExtraLineQuestionViewDelegate!
    
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
        self.addSubview(label)
        label.snp_makeConstraints {
            $0.top.equalTo(0)
            $0.centerX.equalTo(0)
            $0.width.equalTo(self.snp_width).offset(-30)
            return
        }
        label.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        label.textColor = UIColor(white: 0.15, alpha: 1)
        label.text = "If you live in an apartment or this is a PO box, please enter the number below"
        label.textAlignment = .Center
        label.numberOfLines = 0
        
        self.addSubview(extraTextField)
        extraTextField.snp_makeConstraints {
            $0.top.equalTo(label.snp_bottom).offset(10)
            $0.width.equalTo(label.snp_width)
            $0.height.equalTo(40)
            $0.centerX.equalTo(0)
            return
        }
        extraTextField.backgroundColor = UIColor(white: 0.9, alpha: 1)
        extraTextField.font = UIFont(name: "HelveticaNeue-Light", size: 25)
        extraTextField.textColor = UIColor(white: 0.1, alpha: 1)
        extraTextField.placeholder = "PO Box 123"
        extraTextField.textAlignment = .Center
        
        //Add continue button
        self.addSubview(submitButton)
        submitButton.snp_makeConstraints {
            $0.width.equalTo(200)
            $0.height.equalTo(45)
            $0.top.equalTo(extraTextField.snp_bottom).offset(10)
            $0.centerX.equalTo(0)
        }
        submitButton.color = UIColor.FlatGreen
        submitButton.title = "Continue"
        submitButton.addTarget(self, action: "continueWasClicked", forControlEvents: .TouchUpInside)
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
    func continueWasClicked() {
        if let text = extraTextField.text where text != "" {
            self.delegate.addressExtraLineWasEntered(text)
        } else {
            self.delegate.addressExtraLineWasEntered(nil)
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //External / Delegate Handlers
    //-----------------------------------------------------------------------------------------------------
}

