import SwiftRewriterLib
import SwiftAST

/// Simplifies AST structures that may be unnecessarily complex.
public class ASTSimplifier: SyntaxNodeRewriterPass {
    public override func visitCompound(_ stmt: CompoundStatement) -> Statement {
        guard stmt.statements.count == 1, let doStmt = stmt.statements[0].asDoStatement else {
            return super.visitCompound(stmt)
        }
        
        stmt.statements = doStmt.body.statements
        
        for def in doStmt.body.allDefinitions() {
            stmt.definitions.recordDefinition(def)
        }
        
        notifyChange()
        
        return super.visitCompound(stmt)
    }
    
    /// Simplify check before invoking nullable closure
    public override func visitIf(_ stmt: IfStatement) -> Statement {
        nullCheck:
        if stmt.elseBody == nil, let nullCheckMember = stmt.nullCheckMember, nullCheckMember.asIdentifier != nil {
            guard stmt.body.statements.count == 1 else {
                break nullCheck
            }
            let body = stmt.body.statements[0]
            guard body.asExpressions?.expressions.count == 1, let exp = body.asExpressions?.expressions.first else {
                break nullCheck
            }
            guard let postfix = exp.asPostfix, postfix.exp == nullCheckMember else {
                break nullCheck
            }
            guard postfix.functionCall != nil else {
                break nullCheck
            }
            
            let statement =
                Statement
                    .expression(
                        PostfixExpression(exp: postfix.exp, op: .optionalAccess(postfix.op))
            )
            
            notifyChange()
            
            return super.visitStatement(statement)
        }
        
        return super.visitIf(stmt)
    }
}

extension IfStatement {
    var isNullCheck: Bool {
        // `if (nullablePointer) { ... }`-style checking:
        // An if-statement over a nullable value is also considered a null-check
        // in Objective-C.
        if exp.resolvedType?.isOptional == true {
            return true
        }
        
        guard let binary = exp.asBinary else {
            return false
        }
        
        return binary.op == .unequals && binary.rhs == .constant(.nil)
    }
    
    var nullCheckMember: Expression? {
        guard isNullCheck else {
            return nil
        }
        
        // `if (nullablePointer) { ... }`-style checking
        if exp.resolvedType?.isOptional == true {
            return exp
        }
        
        if let binary = exp.asBinary {
            return binary.rhs == .constant(.nil) ? binary.lhs : binary.rhs
        }
        
        return nil
    }
}