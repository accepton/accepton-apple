import UIKit

extension UIColor {
    convenience init(var hex24: String, alpha: CGFloat=1) {
        if hex24.characters.first == "#" {
            hex24.removeAtIndex(hex24.startIndex)
        }
        
        //Get HEX value
        var rgbValue: UInt32 = 0
        NSScanner(string: hex24).scanHexInt(&rgbValue)
        
        let r = (rgbValue & 0xFF0000) >> 16
        let g = (rgbValue & 0x00FF00) >> 8
        let b = (rgbValue & 0x0000FF) >> 0
        
        let rf = CGFloat(r) / 255
        let gf = CGFloat(g) / 255
        let bf = CGFloat(b) / 255
        
        self.init(red: rf, green: gf, blue: bf, alpha: alpha)
    }
    
    static var FlatGreen: UIColor {
        return UIColor(hex24: "86e7c5")
    }
    
    static var FlatBlue: UIColor {
        return UIColor(hex24: "84cbe8")
    }
    
    static var FlatPurple: UIColor {
        return UIColor(hex24: "8499e8")
    }
    
    static var FlatPink: UIColor {
        return UIColor(hex24: "cc85e6")
    }
    
    static var FlatRed: UIColor {
        return UIColor(hex24: "e69286")
    }
}