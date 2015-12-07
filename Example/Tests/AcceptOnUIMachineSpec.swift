// https://github.com/Quick/Quick

import Quick
import Nimble
import accepton

@objc public class AcceptOnUIMachineSpecDelegate : NSObject, AcceptOnUIMachineDelegate {
    override public init() {
        super.init()
    }
    
    
    //Stores an event log of all the acceptOnUIMachineXXX delegate response calls
    public var delegateEventLog: [String] = []
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
        delegateEventLog.append("acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:\(name)")
        creditCardValidationErrors.insertObject(["name":name, "msg":msg], atIndex: 0)
    }
    
    public var creditCardNoValidationErrors = NSMutableArray()
    public func acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName(name: String, withValue value: String) {
        delegateEventLog.append("acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:\(name)")
        creditCardNoValidationErrors.insertObject(["name": name, "value":value], atIndex: 0)
    }
    
    public func acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName(name: String) {
        delegateEventLog.append("acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName:\(name)")
    }
    
    public var emphasizeValidationErrorCount = 0
    public func acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String) {
        delegateEventLog.append("acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName:\(name)")
        emphasizeValidationErrorCount += 1
    }
    
    public func acceptOnUIMachinePaymentIsProcessing(paymentType: String) {
        delegateEventLog.append("acceptOnUIMachinePaymentIsProcessing:\(paymentType)")
    }
    
    public var creditCardTypeTransitions: [String] = []
    public func acceptOnUIMachineCreditCardTypeDidChange(type: String) {
        delegateEventLog.append("acceptOnUIMachineCreditCardTypeDidChange:\(type)")
        creditCardTypeTransitions.append(type)
    }
    
    public var initialFieldValues: [String:String] = [:]
    public func acceptOnUIMachineDidSetInitialFieldValueWithName(name: String, withValue value: String) {
        initialFieldValues[name] = value
    }
}

class AcceptOnUIMachineSpec: QuickSpec {
    override func spec() {
        describe("init") {
            it("can be created with a public or secret key") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "test", isProduction: false)
                uim.delegate = delegate
                let uim2 = AcceptOnUIMachine.init(secretKey: "test2", isProduction: false)
                uim2.delegate = delegate
            }
        }
        
        describe("loading") {
            it("does fail to load with Unauthorized error if given a non-existent key") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "test", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                expect {
                    return delegate.didFailBeginError?.code
                    }.toEventually(equal(AcceptOnAPIError.Code.Unauthorized.rawValue))
            }
            
            it("does fail to load with DevelopeError error if begin is called twice") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "test", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                expect {
                    return delegate.didFailBeginError?.code
                    }.toEventually(equal(AcceptOnUIMachineError.Code.DeveloperError.rawValue))
            }
            
            it("does succeed to load with a good key") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
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
                
                expect {
                    return delegate.beginOptions?.hasApplePay
                    }.toEventually(beTrue())
            }
        }
        
        describe("credit-card email field validation") {
            it("Does not trigger validation error if no email is entered but the focus is not changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    uim.creditCardFieldDidFocusWithName("email")
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toNotEventually(beGreaterThan(0))
            }
            
            it("Does trigger validation error if no email is entered and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    uim.creditCardFieldDidFocusWithName("email")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(beGreaterThan(0))
            }
            
            it("Does not trigger a validation error if a valid email is entered and the focus is changed, and update the field") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    uim.creditCardFieldDidFocusWithName("email")
                    uim.creditCardFieldWithName("email", didUpdateWithString: "test@test.com")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                //Ensure there are no errors
                expect {
                    return delegate.creditCardNoValidationErrors.count
                    }.toEventually(equal(1))
            }
            
            it("Does trigger a validation error if an invalid email is entered and the focus is changed, and update the field") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    uim.creditCardFieldDidFocusWithName("email")
                    uim.creditCardFieldWithName("email", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(equal(1))
            }
            
            it("Does trigger a validation error if an invalid email is entered and the focus is changed, and update the field, but then hides validation when the email is fixed and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    //First we enter an invalid email
                    uim.creditCardFieldDidFocusWithName("email")
                    uim.creditCardFieldWithName("email", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                    
                    //Now we fix the email
                    uim.creditCardFieldDidFocusWithName("email")
                    uim.creditCardFieldWithName("email", didUpdateWithString: "test@test.com")
                    uim.creditCardFieldDidLoseFocus()
                    
                }
                
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal(["acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:email", "acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName:email", "acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:email"]))
            }
            
            it("Does trigger a emphasize error if an invalid email is entered and the focus is changed, and update the field, but then hides validation when the email is *not* fixed and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    //First we enter an invalid email
                    uim.creditCardFieldDidFocusWithName("email")
                    uim.creditCardFieldWithName("email", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                    
                    //Now we fix the email
                    uim.creditCardFieldDidFocusWithName("email")
                    uim.creditCardFieldWithName("email", didUpdateWithString: "test2")
                    uim.creditCardFieldDidLoseFocus()
                    
                }
                
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal(["acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:email", "acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName:email"]))
            }
        }
        
        describe("credit-card card number field validation") {
            it("Does not trigger validation error if no card number is entered but the focus is not changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    uim.creditCardFieldDidFocusWithName("cardNum")
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toNotEventually(beGreaterThan(0))
            }
            
            it("Does trigger validation error if no card number is entered and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(beGreaterThan(0))
            }
            
            it("Does not trigger a validation error if a valid card number is entered and the focus is changed, and update the field") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "4242424242424242")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                //Ensure there are no errors
                expect {
                    return delegate.creditCardNoValidationErrors.count
                    }.toEventually(equal(1))
            }
            
            it("Does trigger a validation error if an invalid card number is entered and the focus is changed, and update the field") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(equal(1))
            }
            
            it("Does trigger a validation error if an invalid card number is entered and the focus is changed, and update the field, but then hides validation when the card number is fixed and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    //First we enter an invalid cardNum
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                    
                    //Now we fix the cardNum
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "4242424242424242")
                    uim.creditCardFieldDidLoseFocus()
                    
                }
                
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal(["acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:cardNum", "acceptOnUIMachineCreditCardTypeDidChange:visa", "acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName:cardNum", "acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:cardNum"]))
            }
            
            it("Does trigger acceptOnUIMachineCreditCardTypeDidChange when card number can be deduced") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    //First we enter an invalid cardNum
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    
                    //Go through different brands prefixes
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "4")    //visa
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "37")   //amex
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "6011") //discover
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "50")   //master-card
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "99")   //unknown
                }
                
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal([
                        "acceptOnUIMachineCreditCardTypeDidChange:visa",
                        "acceptOnUIMachineCreditCardTypeDidChange:amex",
                        "acceptOnUIMachineCreditCardTypeDidChange:discover",
                        "acceptOnUIMachineCreditCardTypeDidChange:master_card",
                        "acceptOnUIMachineCreditCardTypeDidChange:unknown",
                        ]))
            }
        }
        
        describe("expMonth field validation") {
            it("Does not trigger validation error if no expMonth is entered but the focus is not changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    uim.creditCardFieldDidFocusWithName("expMonth")
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toNotEventually(beGreaterThan(0))
            }
            
            it("Does trigger validation error if no expMonth is entered and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    uim.creditCardFieldDidFocusWithName("expMonth")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(beGreaterThan(0))
            }
            
            it("Does not trigger a validation error if a valid expMonth is entered and the focus is changed, and update the field") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    uim.creditCardFieldDidFocusWithName("expMonth")
                    uim.creditCardFieldWithName("expMonth", didUpdateWithString: "08")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                //Ensure there are no errors
                expect {
                    return delegate.creditCardNoValidationErrors.count
                    }.toEventually(equal(1))
            }
            
            it("Does trigger a validation error if an invalid expMonth is entered and the focus is changed, and update the field") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    uim.creditCardFieldDidFocusWithName("expMonth")
                    uim.creditCardFieldWithName("expMonth", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(equal(1))
            }
            
            it("Does trigger a validation error if an invalid expMonth is entered and the focus is changed, and update the field, but then hides validation when the expMonth is fixed and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    //First we enter an invalid expMonth
                    uim.creditCardFieldDidFocusWithName("expMonth")
                    uim.creditCardFieldWithName("expMonth", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                    
                    //Now we fix the expMonth
                    uim.creditCardFieldDidFocusWithName("expMonth")
                    uim.creditCardFieldWithName("expMonth", didUpdateWithString: "09")
                    uim.creditCardFieldDidLoseFocus()
                    
                }
                
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal(["acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expMonth", "acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName:expMonth", "acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:expMonth"]))
            }
            
            
            it("Does trigger a emphasize error if an invalid expMonth is entered and the focus is changed, and update the field, but then hides validation when the expMonth is *not* fixed and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    //First we enter an invalid expMonth
                    uim.creditCardFieldDidFocusWithName("expMonth")
                    uim.creditCardFieldWithName("expMonth", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                    
                    //Now we fix the expMonth
                    uim.creditCardFieldDidFocusWithName("expMonth")
                    uim.creditCardFieldWithName("expMonth", didUpdateWithString: "test2")
                    uim.creditCardFieldDidLoseFocus()
                    
                }
                
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal(["acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expMonth", "acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName:expMonth"]))
            }
            
        }
        
        describe("expYear field validation") {
            it("Does not trigger validation error if no expYear is entered but the focus is not changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    uim.creditCardFieldDidFocusWithName("expYear")
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toNotEventually(beGreaterThan(0))
            }
            
            it("Does trigger validation error if no expYear is entered and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    uim.creditCardFieldDidFocusWithName("expYear")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(beGreaterThan(0))
            }
            
            it("Does not trigger a validation error if a valid expYear is entered and the focus is changed, and update the field") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    uim.creditCardFieldDidFocusWithName("expYear")
                    uim.creditCardFieldWithName("expYear", didUpdateWithString: "88")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                //Ensure there are no errors
                expect {
                    return delegate.creditCardNoValidationErrors.count
                    }.toEventually(equal(1))
            }
            
            it("Does trigger a validation error if an invalid expYear is entered and the focus is changed, and update the field") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    uim.creditCardFieldDidFocusWithName("expYear")
                    uim.creditCardFieldWithName("expYear", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(equal(1))
            }
            
            it("Does trigger a validation error if an invalid expYear is entered and the focus is changed, and update the field, but then hides validation when the expYear is fixed and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    //First we enter an invalid expYear
                    uim.creditCardFieldDidFocusWithName("expYear")
                    uim.creditCardFieldWithName("expYear", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                    
                    //Now we fix the expYear
                    uim.creditCardFieldDidFocusWithName("expYear")
                    uim.creditCardFieldWithName("expYear", didUpdateWithString: "92")
                    uim.creditCardFieldDidLoseFocus()
                    
                }
                
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal(["acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expYear", "acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName:expYear", "acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:expYear"]))
            }
            
            it("Does trigger a emphasize error if an invalid expYear is entered and the focus is changed, and update the field, but then hides validation when the expYear is *not* fixed and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    //First we enter an invalid expYear
                    uim.creditCardFieldDidFocusWithName("expYear")
                    uim.creditCardFieldWithName("expYear", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                    
                    //Now we fix the expYear
                    uim.creditCardFieldDidFocusWithName("expYear")
                    uim.creditCardFieldWithName("expYear", didUpdateWithString: "test2")
                    uim.creditCardFieldDidLoseFocus()
                    
                }
                
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal(["acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expYear", "acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName:expYear"]))
            }
            
        }
        
        describe("security field validation") {
            it("Does not trigger validation error if no security is entered but the focus is not changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    uim.creditCardFieldDidFocusWithName("security")
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toNotEventually(beGreaterThan(0))
            }
            
            it("Does trigger validation error if no security is entered and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    uim.creditCardFieldDidFocusWithName("security")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(beGreaterThan(0))
            }
            
            it("Does not trigger a validation error if a valid security is entered and the focus is changed, and update the field") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    uim.creditCardFieldDidFocusWithName("security")
                    uim.creditCardFieldWithName("security", didUpdateWithString: "1234")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                //Ensure there are no errors
                expect {
                    return delegate.creditCardNoValidationErrors.count
                    }.toEventually(equal(1))
            }
            
            it("Does trigger a validation error if an invalid security is entered and the focus is changed, and update the field") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    uim.creditCardFieldDidFocusWithName("security")
                    uim.creditCardFieldWithName("security", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(equal(1))
            }
            
            it("Does trigger a validation error if an invalid security is entered and the focus is changed, and update the field, but then hides validation when the security is fixed and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    //First we enter an invalid security
                    uim.creditCardFieldDidFocusWithName("security")
                    uim.creditCardFieldWithName("security", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                    
                    //Now we fix the security
                    uim.creditCardFieldDidFocusWithName("security")
                    uim.creditCardFieldWithName("security", didUpdateWithString: "1234")
                    uim.creditCardFieldDidLoseFocus()
                    
                }
                
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal(["acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:security", "acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName:security", "acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:security"]))
            }
            
            it("Does trigger a emphasize error if an invalid security is entered and the focus is changed, and update the field, but then hides validation when the security is *not* fixed and the focus is changed") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    //First we enter an invalid security
                    uim.creditCardFieldDidFocusWithName("security")
                    uim.creditCardFieldWithName("security", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                    
                    //Now we fix the security
                    uim.creditCardFieldDidFocusWithName("security")
                    uim.creditCardFieldWithName("security", didUpdateWithString: "test2")
                    uim.creditCardFieldDidLoseFocus()
                    
                }
                
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal(["acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:security", "acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName:security"]))
            }
        }
        
        describe("pay button") {
            it("Does trigger validation of all fields") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    //We enter a valid card number
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "4242424242424242")
                    uim.creditCardFieldDidLoseFocus()
                    
                    uim.creditCardPayClicked()
                }
                
                //All fields should be simultaneously validated
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal([
                        "acceptOnUIMachineCreditCardTypeDidChange:visa",
                        "acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:cardNum",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:email",
                        "acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:cardNum",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expMonth",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expYear",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:security",
                        ]))
            }
            
            it("Does trigger emphasize on fields that still have errors") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    //We enter a valid card number
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "<invalid card number>")
                    uim.creditCardFieldDidLoseFocus()
                    
                    uim.creditCardPayClicked()
                }
                
                //All fields should be simultaneously validated
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal([
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:cardNum",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:email",
                        "acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName:cardNum",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expMonth",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expYear",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:security",
                        ]))
            }
            
            it("Does trigger hide error on fields that had errors but no longer do") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    //Enter in an invalid card first
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                    
                    //Update the credit-card number field to a valid value but don't switch focus
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "4242424242424242")
                    
                    uim.creditCardPayClicked()
                }
                
                //All fields should be simultaneously validated
                expect {
                    return delegate.delegateEventLog
                    }.toEventually(equal([
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:cardNum",
                        "acceptOnUIMachineCreditCardTypeDidChange:visa",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:email",
                        "acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName:cardNum",
                        "acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:cardNum",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expMonth",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expYear",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:security",
                        ]))
            }
            
            it("Does call acceptOnUIMachinePaymentIsProcessing when validated information is entered") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()

                    //Enter valid information
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "4242424242424242")
                    
                    uim.creditCardFieldDidFocusWithName("email")
                    uim.creditCardFieldWithName("email", didUpdateWithString: "test@test.com")
                    
                    uim.creditCardFieldDidFocusWithName("expMonth")
                    uim.creditCardFieldWithName("expMonth", didUpdateWithString: "04")
                    
                    uim.creditCardFieldDidFocusWithName("expYear")
                    uim.creditCardFieldWithName("expYear", didUpdateWithString: "17")
                    
                    uim.creditCardFieldDidFocusWithName("security")
                    uim.creditCardFieldWithName("security", didUpdateWithString: "123")
                    
                    //Submit
                    uim.creditCardPayClicked()
                }
                
                expect {
                    return delegate.delegateEventLog.last
                    }.toEventually(equal(
                        "acceptOnUIMachinePaymentIsProcessing:credit_card"
                        ))
            }
        }
        
        describe("AcceptOnUIMachineFormOptions") {
            it("Does yield $3.49 when given an amountInCents equal to 349") {
                var token = AcceptOnAPITransactionToken()
                token.amountInCents = 349
                let paymentMethods = AcceptOnAPIPaymentMethodsInfo()
                let options = AcceptOnUIMachineFormOptions(token: token, paymentMethods: paymentMethods)
                expect(options.uiAmount).to(equal("$3.49"))
            }
            
            it("Does yield $0.00 when given an amountInCents equal to 0") {
                var token = AcceptOnAPITransactionToken()
                token.amountInCents = 0
                let paymentMethods = AcceptOnAPIPaymentMethodsInfo()
                let options = AcceptOnUIMachineFormOptions(token: token, paymentMethods: paymentMethods)
                expect(options.uiAmount).to(equal("$0.00"))
            }
        }

        describe("credit-card initial field values") {
            it("Does load email if the user info was specified and the didSwitchToCreditCardForm is called") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                var userInfo = AcceptOnUIMachineOptionalUserInfo()
                userInfo.emailAutofillHint = "test@test.com"
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false, userInfo: userInfo)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                }
                
                //Pay was clicked, so it validated all fields
                expect {
                    return delegate.initialFieldValues["email"]
                }.toEventually(equal("test@test.com"))
            }
            
            it("Does output a validation error if the email is not sane") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                var userInfo = AcceptOnUIMachineOptionalUserInfo()
                userInfo.emailAutofillHint = "test"
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false, userInfo: userInfo)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                }
                
                //Pay was clicked, so it validated all fields
                expect {
                    return delegate.initialFieldValues["email"]
                }.toEventually(equal("test"))

                expect {
                    if delegate.creditCardValidationErrors.count > 0 {
                        let res = delegate.creditCardValidationErrors[0] as! NSDictionary
                        return res["name"] as! String
                    } else {
                        return nil
                    }
                }.toEventually(equal("email"))
            }
        }
        
        describe("creditCardReset") {
            it("Does clear the internal fields associated with the credit-card when the reset is used") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    uim.creditCardFieldDidFocusWithName("email")
                    uim.creditCardFieldWithName("email", didUpdateWithString: "test@test.com")
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "4242424242424242")
                    uim.creditCardFieldDidFocusWithName("expMonth")
                    uim.creditCardFieldWithName("expMonth", didUpdateWithString: "04")
                    uim.creditCardFieldDidFocusWithName("expYear")
                    uim.creditCardFieldWithName("expYear", didUpdateWithString: "20")
                    uim.creditCardFieldDidFocusWithName("security")
                    uim.creditCardFieldWithName("expYear", didUpdateWithString: "1234")
                    uim.didSwitchFromCreditCardForm()
                    
                    //If it didn't reset, then the fields would have been still the same (valid)
                    uim.creditCardPayClicked()
                }
                
                //Pay was clicked, so it validated all fields
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(equal(5))
            }
            
            it("Does clear the internal validation statuses with the credit-card when the reset is used") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    uim.creditCardFieldDidFocusWithName("email")
                    uim.creditCardFieldWithName("email", didUpdateWithString: "<invalid>")
                    
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "<invalid>")
                    
                    uim.creditCardFieldDidFocusWithName("expMonth")
                    uim.creditCardFieldWithName("expMonth", didUpdateWithString: "<invalid>")
                    
                    uim.creditCardFieldDidFocusWithName("expYear")
                    uim.creditCardFieldWithName("expYear", didUpdateWithString: "<invalid>")
                    
                    uim.creditCardFieldDidFocusWithName("security")
                    uim.creditCardFieldWithName("expYear", didUpdateWithString: "<invalid>")
                    uim.creditCardFieldDidLoseFocus()
                    
                    uim.didSwitchFromCreditCardForm()
                    
                    //If it reset, we would get back new 'show' validation errors, not emphasize
                    uim.creditCardPayClicked()
                }
                
                //Pay was clicked, so it validated all fields
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(equal(10))
                
                expect {
                    return delegate.emphasizeValidationErrorCount
                    }.toEventually(equal(0))
            }
            
            it("Does reset the brand type for the credit-card") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    //Set it to visa
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "4242424242424242")
                    
                    uim.didSwitchFromCreditCardForm()
                    
                    //It should now trigger a
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "4242424242424242")
                    
                    //If it reset, there should be two transitions to visa (implied 'unknown' starting state)
                    //if it didn't reset, it still thinks it in visa and won't emit a transition
                    uim.creditCardFieldDidLoseFocus()
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "4")
                }
                
                //Pay was clicked, so it validated all fields
                expect {
                    return delegate.creditCardTypeTransitions
                    }.toEventually(equal(["visa", "visa"]))
            }
        }
        
        describe("paypal") {
            it("Does call acceptOnUIMachinePaymentIsProcessing when paypal is clicked") {
                let delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553", isProduction: false)
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.didSwitchToCreditCardForm()
                    uim.paypalClicked()
                }
                
                expect {
                    return delegate.delegateEventLog.last
                    }.toEventually(equal(
                        "acceptOnUIMachinePaymentIsProcessing:paypal"
                        ))
            }
        }
    }
}
