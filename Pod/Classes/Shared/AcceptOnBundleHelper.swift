import UIKit

class _AcceptOnBundleHelper {
    var bundle: NSBundle!
    
    init() {
        let bundlePath = NSBundle(forClass: self.dynamicType).pathForResource("accepton", ofType: "bundle")!
        bundle = NSBundle(path: bundlePath)
    }
    
    func UIImageNamed(named: String) -> UIImage? {
        let image = UIImage(named: named, inBundle: bundle, compatibleWithTraitCollection: nil)
        return image
    }
}

var AcceptOnBundle = _AcceptOnBundleHelper()