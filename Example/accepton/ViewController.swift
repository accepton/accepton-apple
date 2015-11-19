import UIKit
import accepton

//This contains the 'buy the watch for $10' page on the Main.storyboard
class ViewController : UIViewController, AcceptOnViewControllerDelegate {
    override func viewDidLoad() {
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //Make sure we make ourselves a delegate so we can capture the 'cancel' delegate event
        if let avc = segue.destinationViewController as? AcceptOnViewController {
            avc.delegate = self
            avc.itemDescription = "My Item Description"
            avc.amountInCents = 100
            avc.accessToken = "pkey_0d4502a9bf8430ae"
            avc.isProduction = true
            
            //If you're running in production
            //avc.isProduction = true

            //Optionally, provide an email to use to auto-fill out the email
            //field in the credit card form
            //var userInfo = AcceptOnUIMachineOptionalUserInfo()
            //userInfo.email = "test@test.com"
            //avc.userInfo = userInfo
        }
    }
    
    func acceptOnCancelWasClicked(vc: AcceptOnViewController) {
        //Hide the accept-on UI
        vc.dismissViewControllerAnimated(true) {
        }
    }
    
    func acceptOnPaymentDidSucceed(vc: AcceptOnViewController, withChargeInfo chargeInfo: [String:AnyObject]) {
        //Save this for refunding later, analytics, etc. if you wish
//        let chargeId = chargeInfo["id"] as! String
        
        //Dismiss the modal that we showed in the storyboard
        vc.dismissViewControllerAnimated(true) {
        }
        
        UIAlertView(title: "Hurray!", message: "Your widget was shipped", delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
}