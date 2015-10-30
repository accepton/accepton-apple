import UIKit

//Re-colors a UIImage by using all non-alpha-channel colors as the mask
extension UIImage {
    func imageWithColor(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale);
        let context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, self.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetBlendMode(context, .Normal);
        let rect = CGRectMake(0, 0, self.size.width, self.size.height);
        CGContextClipToMask(context, rect, self.CGImage);
        color.setFill()
        CGContextFillRect(context, rect);
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
}