import UIKit

//This contains the 'buy the watch for $10' page on the Main.storyboard
class ViewController : UIViewController, AcceptOnViewControllerDelegate {
    override func viewDidLoad() {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let avc = segue.destinationViewController as? AcceptOnViewController {
            avc.delegate = self
        }
    }
    
    func acceptOnCancelWasClicked(vc: AcceptOnViewController) {
        vc.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
}