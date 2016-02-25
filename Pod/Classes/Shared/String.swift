import UIKit

extension String {
    /**
     Convert a string from snake case to pascal/capital camel case
     This is useful for class names
     ```
     "foo_bar".snakeToCamelCase => "FooBar"
     ```
     
     - returns: A string in the ClassCase
     */
    var snakeToClassCase: String {
        var ss = NSMutableArray(array: (self as String).componentsSeparatedByString("_") as NSArray)
        
        
        for (var i = 0; i < ss.count; ++i) {
            ss[i] = ss[i].capitalizedString
        }
        
        return ss.componentsJoinedByString("") as String
    }
    
    /**
     Convert a string from snake case to camel case
     
     ```
     "foo_bar".snakeToCamelCase => "fooBar"
     ```
     
     - returns: A string in the camelCase
     */
    var snakeToCamelCase: String {
        var ss = NSMutableArray(array: (self as String).componentsSeparatedByString("_") as NSArray)
        
        
        for (var i = 1; i < ss.count; ++i) {
            ss[i] = ss[i].capitalizedString
        }
        
        return ss.componentsJoinedByString("") as String
    }
    
    /**
     Converts a string with spaces to a string to snake-case
     ```
     "foo_bar".sentenceToSnakeCase => "FooBar"
     ```
     
     - returns: A string in the ClassCase
     */
    var sentenceToSnakeCase: String {
        var ss = NSMutableArray(array: (self as String).componentsSeparatedByString(" ") as NSArray)
        
        
        for (var i = 0; i < ss.count; ++i) {
            ss[i] = ss[i].lowercaseString
        }
        
        return ss.componentsJoinedByString("_") as String
    }
}