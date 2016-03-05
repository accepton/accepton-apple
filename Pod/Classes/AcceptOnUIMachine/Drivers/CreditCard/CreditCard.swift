import PassKit
import UIKit

//Generic credit-card driver interface
@objc public class AcceptOnUIMachineCreditCardDriver: AcceptOnUIMachinePaymentDriver, AcceptOnUIMachineCreditCardDriverPluginDelegate {
    //List of drivers that you want available
    let pluginClasses: [AcceptOnUIMachineCreditCardDriverPlugin.Type] = [
        AcceptOnUIMachineCreditCardBraintreePlugin.self,
        AcceptOnUIMachineCreditCardStripePlugin.self]
    
    //Driver instances that were created
    var plugins: [AcceptOnUIMachineCreditCardDriverPlugin] = []
    let pluginsQueue: NSOperationQueue = {
       let q = NSOperationQueue()
        q.maxConcurrentOperationCount = 1
        return q
    }()
    
    override class var name: String {
        return "credit_card"
    }
    
    public override func beginTransaction() {
        //Credit card transactions set the email
        self.email = formOptions.creditCardParams?.email
        
        for pluginClass in pluginClasses {
            let plugin = pluginClass.init()
            plugin.delegate = self
            plugins.append(plugin)
        }
        
        for plugin in plugins {
            plugin.beginTransactionWithFormOptions(formOptions)
        }
    }
    
    //Called after a plugin succeeds of fails.  Removes plugin from list of plugins and then
    //checks if we've looked at all the plugins
    func markPluginFinished(plugin: AcceptOnUIMachineCreditCardDriverPlugin) {
        pluginsQueue.addOperation(NSBlockOperation() {
            self.plugins.removeAtIndex(self.plugins.indexOf(plugin)!)
        })
        pluginsQueue.waitUntilAllOperationsAreFinished()
        
        //Ready to submit to accepton's API, all plugins returned something (success or failure)
        if plugins.count == 0 {
            readyToCompleteTransaction()
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //AcceptOnUIMachineCreditCardDriverPluginDelegate
    //-----------------------------------------------------------------------------------------------------
    func creditCardPlugin(plugin: AcceptOnUIMachineCreditCardDriverPlugin, didFailWithMessage message: String) {
        puts("[\(self.dynamicType).\(plugin.dynamicType)] did fail with message: \(message)")
        markPluginFinished(plugin)
    }
    
    func creditCardPlugin(plugin: AcceptOnUIMachineCreditCardDriverPlugin, didSucceedWithNonce nonce: String) {
        pluginsQueue.addOperation(NSBlockOperation() {
            self.nonceTokens[plugin.name] = nonce
        })
        pluginsQueue.waitUntilAllOperationsAreFinished()
        markPluginFinished(plugin)
    }
}

protocol AcceptOnUIMachineCreditCardDriverPluginDelegate: class {
    func creditCardPlugin(plugin: AcceptOnUIMachineCreditCardDriverPlugin, didFailWithMessage message: String)
    func creditCardPlugin(plugin: AcceptOnUIMachineCreditCardDriverPlugin, didSucceedWithNonce nonce: String)
}

//Plugins are things like braintree, stripe, etc
class AcceptOnUIMachineCreditCardDriverPlugin: NSObject {
    var name: String {
        assertionFailure("Override name")
        return ""
    }
    
    weak var delegate: AcceptOnUIMachineCreditCardDriverPluginDelegate!
    
    //Start a transaction attempt
    func beginTransactionWithFormOptions(formOptions: AcceptOnUIMachineFormOptions) {}
    
    override required init() {
        
    }
}
