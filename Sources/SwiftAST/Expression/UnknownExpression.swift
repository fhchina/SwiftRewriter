public class UnknownExpression: Expression {
    public var context: UnknownASTContext
    
    public override var description: String {
        return context.description
    }
    
    public init(context: UnknownASTContext) {
        self.context = context
        
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        context =
            try UnknownASTContext(context:
                container.decode(String.self, forKey: .context))
        
        try super.init(from: container.superDecoder())
    }
    
    public override func copy() -> UnknownExpression {
        return UnknownExpression(context: context).copyTypeAndMetadata(from: self)
    }
    
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        return visitor.visitUnknown(self)
    }
    
    public override func isEqual(to other: Expression) -> Bool {
        return other is UnknownExpression
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(context.context, forKey: .context)
        
        try super.encode(to: container.superEncoder())
    }
    
    public static func == (lhs: UnknownExpression, rhs: UnknownExpression) -> Bool {
        return true
    }
    
    private enum CodingKeys: String, CodingKey {
        case context
    }
}
public extension Expression {
    @inlinable
    public var asUnknown: UnknownExpression? {
        return cast()
    }
}
