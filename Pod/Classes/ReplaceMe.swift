import Alamofire

public class Accepton {
    
    public init() {
        
    }
    
    public func holahOnResponse() {
        //Token Stub
        Alamofire.request(.POST, "https://staging-checkout.accepton.com/v1/tokens", parameters: ["access_token":"pkey_24b6fa78e2bf234d", "amount":"1000", "description":"Hipster T-Shirt"]).responseJSON { response in
            
            let id = JSON["id"] as! String
            if let JSON = response.result.value {
                
            }
        }
    }
}