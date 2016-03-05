import UIKit

class FactoryProduct<T, P: Equatable>: NSObject {
    var properties: [P]
    
    var descriptionAddendums: [String:String]?
    
    var block: (()->(T))!
    
    var blockWithRuntimeProperties: (()->(T, [P]))!
    
    var valueEntered = false
    lazy var value: T = {
        
        if self.block != nil {
            return self.block()
        } else {
            let res = self.blockWithRuntimeProperties()
            self.properties += res.1
            return res.0
        }
    }()
    
    init(properties: [P], descriptionAddendums: [String:String], block: ()->(T)) {
        self.properties = properties
        self.descriptionAddendums = descriptionAddendums
        self.block = block
    }

    init(properties: [P], descriptionAddendums: [String:String], blockWithRuntimeProperties: ()->(T, [P])) {
        self.properties = properties
        self.descriptionAddendums = descriptionAddendums
        self.blockWithRuntimeProperties = blockWithRuntimeProperties
    }

    
    override var description: String {
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
        filteredProducts = filteredProducts.filter { product in
            return productMatchesQuery(product)
        }
        
        if filteredProducts.count == 0 {
            print("No products for \(self.dynamicType) were found that matched your query: \(self)")
            assertionFailure()
        }
        
        return filteredProducts
    }
    
    private func productMatchesQuery(product: FactoryProduct<T, P>) -> Bool {
        if let withAtleastProperties = withAtleastProperties {
            for p in withAtleastProperties {
                if product.properties.indexOf(p) == nil { return false }
            }
        }
        
        for p in withoutProperties {
            if product.properties.indexOf(p) != nil { return false }
        }
        
        return true
    }
    
    var description: String {
        return "\nwithAtleastProperties: \(withAtleastProperties)\nwithoutProperties: \(withoutProperties)"
    }
    
    //Loop etc.
    func each(block: (value: T, desc: String)->()) {
        let res = self.runQuery()
        
        var blockArguments: [(value: T, desc: String)] = []
        let blockArgumentsQueue = NSOperationQueue()
        blockArgumentsQueue.maxConcurrentOperationCount = 1

        for var e in res {
            blockArgumentsQueue.addOperation(NSBlockOperation() {
                let v = e.value
                
                if self.productMatchesQuery(e) {
                    let desc = "\(e)"
                    blockArguments.append((value: e.value, desc: desc))
                    
                    if let product = productDescripions[desc] {
                        if product != e {
                            NSException(name: "Factory Error", reason: "Product with description \(desc) had a duplicate", userInfo: nil).raise()
                        }
                    }
                } else {
                    puts("\(e) rejected after running post-query")
                }
            })
        }
        blockArgumentsQueue.waitUntilAllOperationsAreFinished()
        
        for arg in blockArguments {
            block(arg)
        }
    }
    
    func eachWithProperties(block: (value: T, desc: String, properties: [P])->()) {
        let res = self.runQuery()
        for var e in res {
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
    
    var asyncProductsQueue: NSOperationQueue = {
        let q = NSOperationQueue()
        q.maxConcurrentOperationCount = 1
        return q
    }()
    
    required init() {}

    func product(properties properties: [P], var withExtraDesc extraDescs: [String:String]=[:], block: ()->(T)) {
        for (k, v) in currentPrefixExtraDescs { extraDescs[k] = v }
        let product = FactoryProduct<T, P>(properties: properties+currentContextProperties, descriptionAddendums: extraDescs, block: block)
        
        //Do any products have matching descriptions?
        let desc = "\(product)"
        for e in products {
            let otherDesc = "\(e)"
            if otherDesc == desc {
                assertionFailure("product for \(self.dynamicType) with desc \(desc) has duplicates!!")
            }
        }
        
        products.append(product)
    }
    
    func product(properties: P..., withExtraDescs extraDescs: [String:String]=[:], block: ()->(T)) {
        self.product(properties: properties, withExtraDesc: extraDescs, block: block)
    }
    
    //Products that are 'added' after the block is called (because they cannot be computed before hand)
    //can have additional properties which are then checked via filter at the last minute
    func productWithRunTimeProperties(properties properties: [P], var withExtraDesc extraDescs: [String:String]=[:], block: ()->(value: T, extraProperties: [P])) {
        for (k, v) in currentPrefixExtraDescs { extraDescs[k] = v }
        
        var extraProperties: [P]!
        let _block: ()->(T) = {
            let res = block()
            extraProperties = res.extraProperties
            return res.value
        }
        
        let product = FactoryProduct<T, P>(properties: properties+currentContextProperties, descriptionAddendums: extraDescs, blockWithRuntimeProperties: block)
        
        //Do any products have matching descriptions?
        let desc = "\(product)"
        for e in products {
            let otherDesc = "\(e)"
            if otherDesc == desc {
                assertionFailure("product for \(self.dynamicType) with desc \(desc) has duplicates!!")
            }
        }
        
        products.append(product)
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
//        let factory = factoryWithType(t: T.self, p: P.self)
        let factory = factoryWithKlass(self)
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

private var productDescripions: [NSObject:String] = [:]

private var factories: [String:AnyObject] = [:]
private func factoryWithKlass<T, P>(klass: Factory<T, P>.Type) -> Factory<T, P> {
    let sig = "\(klass)"
    
    if let factory = factories[sig] {
        puts("Factory made \(sig)")
        return factory as! Factory<T, P>
    }
    
    puts("factory new \(sig)")
    let factory = klass.init()
    factories[sig] = factory
    
    return factoryWithKlass(klass)
}