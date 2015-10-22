// https://github.com/Quick/Quick

import Quick
import Nimble
import accepton

@objc public class AcceptOnUIMachineSpecDelegate : NSObject, AcceptOnUIMachineDelegate {
    override public init() {
        super.init()
    }
    
    public var beginOptions: AcceptOnUIMachineFormOptions?
    public func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions) {
        beginOptions = options
    }
    
    public var didFailBeginError: NSError?
    public func acceptOnUIMachineDidFailBegin(error: NSError) {
        didFailBeginError = error
    }
}

class AcceptOnUIMachineSpec: QuickSpec {
    override func spec() {
        describe("init") {
            it("can be created with a public or secret key") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "test")
                uim.delegate = delegate
                let uim2 = AcceptOnUIMachine.init(secretKey: "test2")
                uim2.delegate = delegate
            }
        }
        
        describe("loading") {
            it("does fail to load with Unauthorized error if given a non-existent key") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "test")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                expect {
                    return delegate.didFailBeginError?.code
                }.toEventually(equal(AcceptOnAPIError.Code.Unauthorized.rawValue))
            }
            
            it("does fail to load with DevelopeError error if begin is called twice") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "test")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                expect {
                    return delegate.didFailBeginError?.code
                }.toEventually(equal(AcceptOnUIMachineError.Code.DeveloperError.rawValue))
            }
            
            it("does succeed to load with a good key") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                expect {
                    return delegate.beginOptions
                }.toNotEventually(beNil())
                
                //Should have a credit-card form & paylpal button
                expect {
                    return delegate.beginOptions?.hasCreditCardForm
                }.toEventually(beTrue())
                
                expect {
                    return delegate.beginOptions?.hasPaypalButton
                }.toEventually(beTrue())
            }
        }
        
        describe("AcceptOnUIMachineFormOptions") {
            it("Does yield $3.49 when given an amountInCents equal to 349") {
                var token = AcceptOnAPITransactionToken()
                token.amountInCents = 349
                let paymentMethods = AcceptOnAPIPaymentMethodsInfo()
                var options = AcceptOnUIMachineFormOptions(token: token, paymentMethods: paymentMethods)
                expect(options.uiAmount).to(equal("$3.49"))
            }
            
            it("Does yield $0.00 when given an amountInCents equal to 0") {
                var token = AcceptOnAPITransactionToken()
                token.amountInCents = 0
                let paymentMethods = AcceptOnAPIPaymentMethodsInfo()
                var options = AcceptOnUIMachineFormOptions(token: token, paymentMethods: paymentMethods)
                expect(options.uiAmount).to(equal("$0.00"))
            }
        }
    }
}