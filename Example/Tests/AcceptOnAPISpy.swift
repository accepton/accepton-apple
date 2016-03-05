import accepton

//Actual API class
public class AcceptOnAPISpy: AcceptOnAPI, Spy {
    convenience init(_ api: AcceptOnAPI) {
        self.init(publicKey: api.accessToken, isProduction: api.isProduction)
    }
    
    var callLog: [(name: String, args: [String:AnyObject])] = []
    override public func createTransactionTokenWithDescription(description: String, forAmountInCents amount: Int, completion: (token: AcceptOnAPITransactionToken?, error: NSError?) -> ()) {
        logCall("createTransactionTokenWithDescription:forAmountInCents:", withArgs: ["description": description, "forAmountInCents": amount])
        
        super.createTransactionTokenWithDescription(description, forAmountInCents: amount, completion: completion)
        
    }
    
//    override public func getAvailablePaymentMethodsForTransactionWithId(tid: String, completion: (paymentMethods: AcceptOnAPIPaymentMethodsInfo?, error: NSError?) -> ()) {
//        
//    }
    
    //WIP: Need to get stripe or paypal to work before I can test this
    override public func chargeWithTransactionId(tid: String, andChargeinfo chargeInfo: AcceptOnAPIChargeInfo, completion: (chargeRes: [String: AnyObject]?, error: NSError?) -> ()) {
            logCall("chargeWithTransactionId:andChargeInfo:", withArgs: ["tid": tid, "chargeInfo": chargeInfo])
        super.chargeWithTransactionId(tid, andChargeinfo: chargeInfo, completion: completion)
    }
    
    //WIP: Need to be able to make charges to test this
//    override public func refundChargeWithTransactionId(tid: String, andChargeId chargeId: String, forAmountInCents amountInCents: Int, completion: (refundRes: [String: AnyObject]?, error: NSError?) -> ()) {
//    }
    
    //-----------------------------------------------------------------------------------------------------
    //PayPal verification endpoint, the first card token should be the paypal payment token
    //-----------------------------------------------------------------------------------------------------
//    override public func verifyPaypalWithTransactionId(tid: String, andChargeInfo chargeInfo: AcceptOnAPIChargeInfo, completion: (chargeRes: [String: AnyObject]?, error: NSError?) -> ()) {
//    }
}
