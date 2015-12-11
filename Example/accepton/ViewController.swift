import UIKit
import accepton

//This contains the 'buy the watch for $10' page on the Main.storyboard
class ViewController : UIViewController, AcceptOnViewControllerDelegate, AcceptOnFillOutRemainingViewDelegate {
    var picker = AcceptOnAddressPickerView()
    
    var api: AcceptOnAPI {
        return AcceptOnAPI.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
    }
    
    override func viewDidLoad() {
        
        let view = UIView()
        view.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(view)
        view.snp_makeConstraints {
            $0.left.top.bottom.right.equalTo(0)
        }
        
        var remainingOptions = AcceptOnFillOutRemainingOptions(options: [.ShippingAddress, .BillingAddress], billingAutocompleteSuggested: nil, shippingAutocompleteSuggested: nil)
        let fillOutRemaining = AcceptOnFillOutRemainingView(remainingOptions: remainingOptions)
        
        view.addSubview(fillOutRemaining)
        fillOutRemaining.snp_makeConstraints {
            $0.left.top.right.bottom.equalTo(0)
            return
        }
        fillOutRemaining.delegate = self
        
        
//        self.view.addSubview(picker)
//        picker.snp_makeConstraints {
//            $0.size.equalTo(self.view.snp_size)
//            $0.center.equalTo(self.view.snp_center)
//            return
//        }
//        
//        picker.delegate = self

        
    }
    
    func fillOutRemainingDidProvideInformation(userInfo: AcceptOnUIMachineUserInfo) {
        
    }
    
//    func addressInputDidUpdate(picker: AcceptOnAddressPickerView, text: String) {
//        let api = AcceptOnAPI.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
//        var address: AcceptOnAPIAddress?
//        
//        api.autoCompleteAddress(text) { _addresses, err in
//            var addresses: [(description: String, tag: String)] = []
//            for e in _addresses! {
//                addresses.append((description: e.description, tag: e.placeId))
//            }
//            picker.updateAddressList(addresses)
//        }
//    }
//    
    func addressWasSelected(picker: AcceptOnAddressPickerView, tag: String) {
        
    }
    
    func fillOutRemainingDidCancel() {
    }
    
    func fillOutRemainingDidProvideInformation(info: [AcceptOnFillOutRemainingOption : Any?]) {
        puts("Info = \(info)")
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
            var userInfo = AcceptOnUIMachineOptionalUserInfo()
            userInfo.requestsAndRequiresShippingAddress = true
            avc.userInfo = userInfo
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