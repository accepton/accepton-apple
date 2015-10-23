// https://github.com/Quick/Quick

import Quick
import Nimble
import accepton

@objc public class AcceptOnUIMachineSpecDelegate : NSObject, AcceptOnUIMachineDelegate {
    override public init() {
        super.init()
    }
    
    var ready: (()->())?
    public func whenReady(ready: (()->())) {
        self.ready = ready
    }
    
    public var beginOptions: AcceptOnUIMachineFormOptions?
    public func acceptOnUIMachineDidFinishBeginWithFormOptions(options: AcceptOnUIMachineFormOptions) {
        beginOptions = options
        ready?()
    }
    
    public var didFailBeginError: NSError?
    public func acceptOnUIMachineDidFailBegin(error: NSError) {
        didFailBeginError = error
    }
    
    public var creditCardValidationErrors = NSMutableArray()
    public func acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String) {
        creditCardValidationErrors.insertObject(["name":name, "msg":msg], atIndex: 0)
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
        
        describe("email field validation") {
            it("Does not trigger validation error if no email is entered but the focus is not changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("email")
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                }.toNotEventually(beGreaterThan(0))
            }
            
            it("Does trigger validation error if no email is entered and the focus is changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)

                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("email")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                }.toEventually(beGreaterThan(0))
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