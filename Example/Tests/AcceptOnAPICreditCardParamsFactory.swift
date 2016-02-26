import accepton

enum AcceptOnAPICreditCardParamsFactoryProperty {
    case Visa
    case FourTwoPattern
}

class AcceptOnAPICreditCardParamsFactory: Factory<AcceptOnAPICreditCardParams, AcceptOnAPICreditCardParamsFactoryProperty> {
    required init() {
        super.init()
        
        product(.Visa, .FourTwoPattern, withExtraDesc: [
            "month": "04"
        ]) {
            return AcceptOnAPICreditCardParams(number: "4242424242424242", expMonth: "04", expYear: "20", cvc: "123", email: "test@test.com")
        }
        
        product(.Visa, .FourTwoPattern, withExtraDesc: [
            "month": "06"
        ]) {
            return AcceptOnAPICreditCardParams(number: "4242424242424242", expMonth: "06", expYear: "20", cvc: "123", email: "test@test.com")
        }
    }
}