import UIKit

class GoogleAnalytics {
    //This is the UA identifier
    static var trackingId: String! = "UA-73782424-1"
    
    static var clientId: String {
        return UIDevice.currentDevice().identifierForVendor?.UUIDString ?? "<no-identifier-for-vendor>"
    }
    
    static var documentHost = NSBundle.mainBundle().bundleIdentifier ?? "com.no.bundle.id"
    
    //Track a page-view
    static func trackPageNamed(name: String) {
        let params: [String:AnyObject] = [
            "tid": trackingId,
            "cid": clientId,
            "t": "pageview",
            "dh": documentHost,
            "dp": "/\(name.sentenceToSnakeCase)",
            "dt": name,
            "v": 1,
        ]
        
        makeRequest(params)
    }
    
    static var url = "https://ssl.google-analytics.com/collect"
    
    static func makeRequest(params: [String:AnyObject]) {
        request(.GET, url, parameters: params).response { (req, res, data, err) -> Void in
        }
    }
}