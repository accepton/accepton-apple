struct FactoryProduct<T, P: Equatable>: CustomStringConvertible {
    var properties: [P]
    
    var descriptionAddendums: [String:String]?
    
    var value: T!
    
    var description: String {
        var res = "\(T.self) with properties: ["
        for p in properties {
            res += "\(p)"
        }
        res += "]"
        
        if let addendums = descriptionAddendums {
            for (k, v) in addendums {
                res += "\n\(k): \(v)"
            }
        }
        return res
    }
}

class FactoryResultQuery<T, P: Equatable>: CustomStringConvertible {
    var factory: Factory<T, P>
    var withAtleastProperties: [P]?
    var withoutProperties: [P] = []

    init(factory: Factory<T, P>) {
        self.factory = factory
    }
    
    //Run the query with the given list of options
    private func runQuery() -> [FactoryProduct<T, P>] {
        //Start out matching all
        var filteredProducts = factory.products
        
        //Must contain all mentioned properties if withAtLeastProperties is set
        if let withAtleastProperties = withAtleastProperties {
            filteredProducts = filteredProducts.filter { product in
                for p in withAtleastProperties {
                    if product.properties.indexOf(p) == nil { return false }
                }
                return true
            }
        }
        
        //Must *not* contain all negatively mentioned properties
        filteredProducts = filteredProducts.filter { product in
            for p in withoutProperties {
                if product.properties.indexOf(p) != nil { return false }
            }
            return true
        }
        
        if filteredProducts.count == 0 {
            print("No products for \(self.dynamicType) were found that matched your query: \(self)")
            assertionFailure()
        }
        
        return filteredProducts
    }
    
    var description: String {
        return "\nwithAtleastProperties: \(withAtleastProperties)\nwithoutProperties: \(withoutProperties)"
    }
    
    //Loop etc.
    func each(block: (value: T, desc: String)->()) {
        let res = runQuery()
        for e in res {
            block(value: e.value, desc: "\(e)")
        }
    }
    
    func eachWithProperties(block: (value: T, desc: String, properties: [P])->()) {
        let res = runQuery()
        for e in res {
            block(value: e.value, desc: "\(e)", properties: e.properties)
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Fluent interface
    //-----------------------------------------------------------------------------------------------------
    func withAtleast(properties properties: [P]) -> FactoryResultQuery<T, P> {
        if self.withAtleastProperties == nil { self.withAtleastProperties = [] }
        self.withAtleastProperties! += properties
        
        return self
    }
    func withAtleast(properties: P...) -> FactoryResultQuery<T, P> { return self.withAtleast(properties: properties) }
    
    func without(properties properties: [P]) -> FactoryResultQuery<T, P> {
        self.withoutProperties += properties
        
        return self
    }
    func without(properties: P...) -> FactoryResultQuery<T, P> { return self.without(properties: properties) }
}

class Factory<T, P: Equatable> {
    var products: [FactoryProduct<T, P>] = []
    
    required init() {}

    func product(properties properties: [P], withExtraDesc extraDescs: [String:String]?=nil, block: ()->(T)) {
        let product = FactoryProduct<T, P>(properties: properties+currentContextProperties, descriptionAddendums: extraDescs, value: block())
        products.append(product)
    }
    
    func product(properties: P..., var withExtraDescs extraDescs: [String:String]=[:], block: ()->(T)) {
        for (k, v) in currentPrefixExtraDescs { extraDescs[k] = v }
        self.product(properties: properties, withExtraDesc: extraDescs, block: block)
    }
    
    var currentPrefixExtraDescs: [String:String]=[:]
    var currentContextProperties: [P] = []
    func context(properties: P..., withExtraDescs extraDescs: [String:String]=[:], block: ()->()) {
        let oldProperties = currentContextProperties
        let oldPrefixExtraDescs = currentPrefixExtraDescs
        currentContextProperties += properties
        for (k, v) in extraDescs { currentPrefixExtraDescs[k] = v }
        block()
        currentContextProperties = oldProperties
        currentPrefixExtraDescs = oldPrefixExtraDescs
    }
    
    static var query: FactoryResultQuery<T, P> {
        let factory = self.init()
        return FactoryResultQuery<T, P>.init(factory: factory)
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Fluent interface
    //-----------------------------------------------------------------------------------------------------
    static func withAtleast(properties: P...) -> FactoryResultQuery<T, P> {
        return self.query.withAtleast(properties: properties)
    }
    
    static func without(properties: P...) -> FactoryResultQuery<T, P> {
        return self.query.without(properties: properties)
    }
    
    static func each(block: (value: T, desc: String)->()) {
        return query.each(block)
    }
    
    static func eachWithProperties(block: (value: T, desc: String, properties: [P])->()) {
        return self.query.eachWithProperties(block)
    }
}