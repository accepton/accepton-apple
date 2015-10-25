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
    
    public func acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName(name: String, withMessage msg: String) {
        delegateEventLog.append("acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName:\(name)")
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
        
        describe("credit-card email field validation") {
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
            
            it("Does not trigger a validation error if a valid email is entered and the focus is changed, and update the field") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("email")
                    uim.creditCardFieldWithName("email", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                }.toEventually(equal(1))
            }

            it("Does trigger a validation error if an invalid email is entered and the focus is changed, and update the field, but then hides validation when the email is fixed and the focus is changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("cardNum")
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toNotEventually(beGreaterThan(0))
            }
            
            it("Does trigger validation error if no card number is entered and the focus is changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(beGreaterThan(0))
            }
            
            it("Does not trigger a validation error if a valid card number is entered and the focus is changed, and update the field") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(equal(1))
            }

            it("Does trigger a validation error if an invalid card number is entered and the focus is changed, and update the field, but then hides validation when the card number is fixed and the focus is changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                }.toEventually(equal(["acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:cardNum", "acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName:cardNum", "acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:cardNum"]))
            }

            it("Does trigger a emphasize error if an invalid cardNum is entered and the focus is changed, and update the field, but then hides validation when the cardNum is *not* fixed and the focus is changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    //First we enter an invalid cardNum
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()

                    //Now we fix the cardNum
                    uim.creditCardFieldDidFocusWithName("cardNum")
                    uim.creditCardFieldWithName("cardNum", didUpdateWithString: "test2")
                    uim.creditCardFieldDidLoseFocus()

                }
                
                expect {
                    return delegate.delegateEventLog
                }.toEventually(equal(["acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:cardNum", "acceptOnUIMachineEmphasizeValidationErrorForCreditCardFieldWithName:cardNum"]))
            }
        }

        describe("expMonth field validation") {
            it("Does not trigger validation error if no expMonth is entered but the focus is not changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("expMonth")
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toNotEventually(beGreaterThan(0))
            }
            
            it("Does trigger validation error if no expMonth is entered and the focus is changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("expMonth")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(beGreaterThan(0))
            }
            
            it("Does not trigger a validation error if a valid expMonth is entered and the focus is changed, and update the field") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("expMonth")
                    uim.creditCardFieldWithName("expMonth", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(equal(1))
            }

            it("Does trigger a validation error if an invalid expMonth is entered and the focus is changed, and update the field, but then hides validation when the expMonth is fixed and the focus is changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("expYear")
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toNotEventually(beGreaterThan(0))
            }
            
            it("Does trigger validation error if no expYear is entered and the focus is changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("expYear")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(beGreaterThan(0))
            }
            
            it("Does not trigger a validation error if a valid expYear is entered and the focus is changed, and update the field") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("expYear")
                    uim.creditCardFieldWithName("expYear", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(equal(1))
            }

            it("Does trigger a validation error if an invalid expYear is entered and the focus is changed, and update the field, but then hides validation when the expYear is fixed and the focus is changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("security")
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toNotEventually(beGreaterThan(0))
            }
            
            it("Does trigger validation error if no security is entered and the focus is changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("security")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(beGreaterThan(0))
            }
            
            it("Does not trigger a validation error if a valid security is entered and the focus is changed, and update the field") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
                    uim.creditCardFieldDidFocusWithName("security")
                    uim.creditCardFieldWithName("security", didUpdateWithString: "test")
                    uim.creditCardFieldDidLoseFocus()
                }
                
                expect {
                    return delegate.creditCardValidationErrors.count
                    }.toEventually(equal(1))
            }

            it("Does trigger a validation error if an invalid security is entered and the focus is changed, and update the field, but then hides validation when the security is fixed and the focus is changed") {
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
              var delegate = AcceptOnUIMachineSpecDelegate()
              let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
              uim.delegate = delegate
              
              uim.beginForItemWithDescription("test", forAmountInCents: 100)
              
              delegate.whenReady() {
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
                "acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:cardNum",
                "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:email",
                "acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:cardNum",
                "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expMonth",
                "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expYear",
                "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:security",
              ]))
          }

        it("Does trigger emphasize on fields that still have errors") {
            var delegate = AcceptOnUIMachineSpecDelegate()
            let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
            uim.delegate = delegate
            
            uim.beginForItemWithDescription("test", forAmountInCents: 100)
            
            delegate.whenReady() {
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
                var delegate = AcceptOnUIMachineSpecDelegate()
                let uim = AcceptOnUIMachine.init(publicKey: "pkey_89f2cc7f2c423553")
                uim.delegate = delegate
                
                uim.beginForItemWithDescription("test", forAmountInCents: 100)
                
                delegate.whenReady() {
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
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:email",
                        "acceptOnUIMachineHideValidationErrorForCreditCardFieldWithName:cardNum",
                        "acceptOnUIMachineSpecFieldUpdatedSuccessfullyWithName:cardNum",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expMonth",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:expYear",
                        "acceptOnUIMachineShowValidationErrorForCreditCardFieldWithName:security",
                        ]))
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
