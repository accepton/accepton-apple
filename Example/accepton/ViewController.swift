import UIKit
import accepton

//This contains the 'buy the watch for $10' page on the Main.storyboard
class ViewController : UIViewController, AcceptOnViewControllerDelegate {
    override func viewDidLoad() {
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //Make sure we make ourselves a delegate so we can capture the 'cancel' delegate event
        if let avc = segue.destinationViewController as? AcceptOnViewController {
            avc.delegate = self/Users/Seo/Library/Group Containers/WSG985FR47.ScreenFlow/A6D1D801-7C0C-4F15-95E5-7AF9BC37020E.scc
            avc.itemDescription = "My Item Description"
            avc.amountInCents = 100
            avc.accessToken = "pkey_89f2cc7f2c423553"
        }
    }
    
    func acceptOnCancelWasClicked(vc: AcceptOnViewController) {
        //Hide the accept-on UI
        vc.dismissViewControllerAnimated(true) {
        }
    }
    
    func acceptOnPaymentDidSucceed(vc: AcceptOnViewController) {
        //Hide the accept-on UI
        vc.dismissViewControllerAnimated(true) {
        }
        
        UIAlertView(title: "Hurray!", message: "Your widget was shipped", delegate: nil, cancelButtonTitle: "Ok").show()
    }
}