#Use with only code

Here is an example ViewController that contains a button that activates the accepton payment:

```swift
import UIKit
import accepton

class ViewController: UIViewController, AcceptOnViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton()
        button.addTarget(self, action: "click", forControlEvents: .TouchUpInside)
        button.frame = CGRectMake(0, 0, 100, 100)
        button.backgroundColor = UIColor.greenColor()
        self.view.addSubview(button)
    }
    
    func click() {
        let avc = AcceptOnViewController()
        avc.delegate = self
        
        //Name of the item you are selling
        avc.itemDescription = "My Item Description"
        
        //The cost in cents of the item
        avc.amountInCents = 100
        
        //The accessToken
        avc.accessToken = "pkey_24b6fa78e2bf234d"
        
        //If you're using this in production
        //avc.isProduction = true
        
        //--------------------------------------------------------------------
        //Optionally, collect billing & shipping, provide auto-fill hints
        //and pass on custom information
        //--------------------------------------------------------------------
        //var userInfo = AcceptOnUIMachineOptionalUserInfo()
        //
        //See the configure section of the README
        //
        //avc.userInfo = userInfo
        
        avc.modalPresentationStyle = .OverCurrentContext
        self.presentViewController(avc, animated: true, completion: nil)
    }

    //User hit the close button, no payment was completed
    func acceptOnCancelWasClicked(vc: AcceptOnViewController) {
        //Hide the accept-on UI
        vc.dismissViewControllerAnimated(true) {
        }
    }
    
    //Payment did succeed, show a confirmation message
    func acceptOnPaymentDidSucceed(vc: AcceptOnViewController, withChargeInfo chargeInfo: [String:AnyObject]) {
        //Save this for refunding later, analytics, etc. if you wish
        let chargeId = chargeInfo["id"] as! String
        
        //Dismiss the modal that we showed in the storyboard
        vc.dismissViewControllerAnimated(true) {
        }
        
        UIAlertView(title: "Hurray!", message: "Your widget was shipped", delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
}
```
