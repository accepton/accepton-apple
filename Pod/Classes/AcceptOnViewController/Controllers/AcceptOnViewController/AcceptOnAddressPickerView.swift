import UIKit
import SnapKit

public protocol AcceptOnAddressPickerViewDelegate: class {
    //The current address the user has typed in, assume it's blank at the start,
    //you should make a call out to your server and then call back the updateAddressList
    //function
    func addressInputDidUpdate(picker: AcceptOnAddressPickerView, text: String)
    
    //The user selected an address with the tag
    func addressWasSelected(picker: AcceptOnAddressPickerView, tag: String)
}

//This view allows the user to select one address by typing in a partial address
public class AcceptOnAddressPickerView: UIView, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate
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
        self.addSubview(inputText)
        inputText.snp_makeConstraints {
            $0.top.equalTo(0)
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
    //Animation Helpers
    //-----------------------------------------------------------------------------------------------------
    
    //-----------------------------------------------------------------------------------------------------
    //Signal / Action Handlers
    //-----------------------------------------------------------------------------------------------------
    
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
        
        self.delegate.addressInputDidUpdate(self, text: newString)
        
        return true
    }
}
