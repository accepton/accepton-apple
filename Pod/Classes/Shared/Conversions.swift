struct USDCents {
    var value: Int
    init(_ value: Int) {
        self.value = value
    }
}

extension USDCents {
    var usdDollarCentsString: String {
        let currencyFormatter = NSNumberFormatter()
        currencyFormatter.numberStyle = .CurrencyStyle
        currencyFormatter.locale = NSLocale(localeIdentifier: "en_US")
        var str = currencyFormatter.stringFromNumber(self.value)!
        str.removeAtIndex(str.startIndex)
        
        return str
    }
}