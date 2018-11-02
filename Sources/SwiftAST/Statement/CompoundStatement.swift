/// Encapsulates a compound statement, that is, a series of statements enclosed
/// within braces.
public class CompoundStatement: Statement, ExpressibleByArrayLiteral {
    /// An empty compound statement.
    public static var empty: CompoundStatement {
        return CompoundStatement()
    }
    
    public var isEmpty: Bool {
        return statements.isEmpty
    }
    
    public var statements: [Statement] = [] {
        didSet {
            oldValue.forEach { $0.parent = nil }
            statements.forEach { $0.parent = self }
        }
    }
    
    public override var children: [SyntaxNode] {
        return statements
    }
    
    public init(statements: [Statement]) {
        self.statements = statements
        
        super.init()
        
        statements.forEach { $0.parent = self }
    }
    
    public required init(arrayLiteral elements: Statement...) {
        self.statements = elements
        
        super.init()
        
        statements.forEach { $0.parent = self }
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        statements = try container.decodeStatements(forKey: .statements)
        
        try super.init(from: container.superDecoder())
        
        statements.forEach { $0.parent = self }
    }
    
    public override func copy() -> CompoundStatement {
        return CompoundStatement(statements: statements.map { $0.copy() }).copyMetadata(from: self)
    }
    
    public override func accept<V: StatementVisitor>(_ visitor: V) -> V.StmtResult {
        return visitor.visitCompound(self)
    }
    
    public override func isEqual(to other: Statement) -> Bool {
        switch other {
        case let rhs as CompoundStatement:
            return statements == rhs.statements
        default:
            return false
        }
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeStatements(statements, forKey: .statements)
        
        try super.encode(to: container.superEncoder())
    }
    
    private enum CodingKeys: String, CodingKey {
        case statements
    }
}

extension CompoundStatement: Sequence {
    public func makeIterator() -> IndexingIterator<[Statement]> {
        return statements.makeIterator()
    }
}

public extension Statement {
    @inlinable
    public var asCompound: CompoundStatement? {
        return cast()
    }
}
