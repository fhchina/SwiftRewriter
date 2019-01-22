import SwiftAST
import Intentions

/// Delegate for controlling some aspects of SwiftSyntax AST generation
public protocol SwiftSyntaxProducerDelegate: class {
    /// Returns whether or not to emit the type annotation for a variable declaration
    /// with a given initial value.
    func swiftSyntaxProducer(_ producer: SwiftSyntaxProducer,
                             shouldEmitTypeFor storage: ValueStorage,
                             intention: Intention?,
                             initialValue: Expression?) -> Bool
    
    /// Returns the initial value for a given value storage intention of a property,
    /// instance variable, or global variable.
    func swiftSyntaxProducer(_ producer: SwiftSyntaxProducer,
                             initialValueFor intention: ValueStorageIntention) -> Expression?
}
