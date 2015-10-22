import UIKit
import accepton

class ViewController: UIViewController, AcceptOnUIMachineDelegate {

    var uim: AcceptOnUIMachine!
    override func viewDidLoad() {
        uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
        uim.delegate = self
        
        uim.beginForItemWithDescription("test", forAmountInCents: 100)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions) {
        print("got options")
    }
    
    func acceptOnUIMachineDidFailToLoadForm(error: NSError) {
        print("error")
    }

}

