import XCTest
import SwiftAST
import Intentions
import TestCommons

class FunctionBodyQueueTests: XCTestCase {
    private var sut: FunctionBodyQueue<EmptyFunctionBodyQueueDelegate>!
    private var delegate: EmptyFunctionBodyQueueDelegate!
    
    override func setUp() {
        super.setUp()
        
        delegate = EmptyFunctionBodyQueueDelegate()
    }
    
    func testQueueGlobalFunctionBody() {
        let intentions =
            IntentionCollectionBuilder()
                .createFile(named: "A") { file in
                    file.createGlobalFunction(withName: "a", body: [])
                }.build()
        let global = intentions.fileIntentions()[0].globalFunctionIntentions[0]
        
        sut = FunctionBodyQueue.fromIntentionCollection(intentions, delegate: delegate, numThreads: 8)
        let items = sut.items
        
        XCTAssertEqual(items.count, 1)
        XCTAssert(items.first?.body === global.functionBody)
    }
    
    func testQueueMethodBody() {
        let intentions =
            IntentionCollectionBuilder()
                .createFile(named: "A") { file in
                    file.createClass(withName: "A") { type in
                        type.createMethod(named: "a") { method in
                            method.setBody([])
                        }
                    }
                }.build()
        let body = intentions.fileIntentions()[0].typeIntentions[0].methods[0].functionBody
        
        sut = FunctionBodyQueue.fromIntentionCollection(intentions, delegate: delegate, numThreads: 8)
        let items = sut.items
        
        XCTAssertEqual(items.count, 1)
        XCTAssert(items.first?.body === body)
    }
    
    func testQueuePropertyGetter() {
        let intentions =
            IntentionCollectionBuilder()
                .createFile(named: "A") { file in
                    file.createClass(withName: "A") { type in
                        type.createProperty(named: "a", type: .int, mode: .computed(FunctionBodyIntention(body: [])))
                    }
                }.build()
        let body = intentions.fileIntentions()[0].typeIntentions[0].properties[0].getter
        
        sut = FunctionBodyQueue.fromIntentionCollection(intentions, delegate: delegate, numThreads: 8)
        let items = sut.items
        
        XCTAssertEqual(items.count, 1)
        XCTAssert(items.first?.body === body)
    }
    
    func testQueuePropertyGetterAndSetter() {
        let intentions =
            IntentionCollectionBuilder()
                .createFile(named: "A") { file in
                    file.createClass(withName: "A") { type in
                        type.createProperty(named: "a", type: .int, mode: .property(get: FunctionBodyIntention(body: []),
                                                                                    set: PropertyGenerationIntention.Setter(valueIdentifier: "setter", body: FunctionBodyIntention(body: []))))
                    }
                }.build()
        let bodyGetter = intentions.fileIntentions()[0].typeIntentions[0].properties[0].getter
        let bodySetter = intentions.fileIntentions()[0].typeIntentions[0].properties[0].setter?.body
        
        sut = FunctionBodyQueue.fromIntentionCollection(intentions, delegate: delegate, numThreads: 8)
        let items = sut.items
        
        XCTAssertEqual(items.count, 2)
        XCTAssert(items.contains(where: { $0.body === bodyGetter }))
        XCTAssert(items.contains(where: { $0.body === bodySetter }))
    }
    
    func testQueueAllBodiesFound() {
        let intentions =
            IntentionCollectionBuilder()
                .createFile(named: "A") { file in
                    file.createGlobalFunction(withName: "a", body: [])
                        .createClass(withName: "B") { type in
                            type.createProperty(named: "b", type: .int, mode: .computed(FunctionBodyIntention(body: [])))
                        }
                }.createFile(named: "C") { file in
                    file.createClass(withName: "C") { type in
                        type.createProperty(named: "c", type: .int, mode: .property(get: FunctionBodyIntention(body: []),
                                                                                    set: PropertyGenerationIntention.Setter(valueIdentifier: "setter", body: FunctionBodyIntention(body: []))))
                    }
                }.build()
        let global = intentions.fileIntentions()[0].globalFunctionIntentions[0].functionBody
        let bodyGetter1 = intentions.fileIntentions()[0].typeIntentions[0].properties[0].getter
        let bodyGetter2 = intentions.fileIntentions()[1].typeIntentions[0].properties[0].getter
        let bodySetter = intentions.fileIntentions()[1].typeIntentions[0].properties[0].setter?.body
        
        sut = FunctionBodyQueue.fromIntentionCollection(intentions, delegate: delegate, numThreads: 8)
        let items = sut.items
        
        XCTAssertEqual(items.count, 4)
        XCTAssert(items.contains(where: { $0.body === global }))
        XCTAssert(items.contains(where: { $0.body === bodyGetter1 }))
        XCTAssert(items.contains(where: { $0.body === bodyGetter2 }))
        XCTAssert(items.contains(where: { $0.body === bodySetter }))
    }
}
