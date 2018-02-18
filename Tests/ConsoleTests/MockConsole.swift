import Foundation
import XCTest
import Console

class MockConsole: Console {
    private var _buffer = OutputBuffer()
    var buffer: String {
        return _buffer.output
    }
    
    let testCase: XCTestCase
    let file: String
    let line: Int
    
    /// Sequence of mock commands
    var commandsInput: [String?] = []
    
    init(testCase: XCTestCase, file: String = #file, line: Int = #line) {
        self.testCase = testCase
        self.file = file
        self.line = line
        
        super.init(output: _buffer)
    }
    
    func addMockInput(line: String?) {
        commandsInput.append(line)
    }
    
    override func readLineWith(prompt: String) -> String? {
        if commandsInput.isEmpty {
            testCase.recordFailure(withDescription: "Unexpected readLineWith with prompt: \(prompt)",
                inFile: file, atLine: line, expected: false)
            return nil
        }
        
        let command = commandsInput.removeFirst()
        
        let ascii = command?.unicodeScalars.map { scalar in
            scalar == "\n" ? "\\n" : scalar.escaped(asASCII: true)
            }.joined(separator: "")
        
        _buffer.output += "[INPUT] '\(ascii ?? "<nil>")'"
        
        return command
    }
    
    override func recordExitCode(_ code: Int) {
        // Trim output so it's easier to test
        _buffer.output =
            _buffer.output
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    public func assert() -> MockConsoleOutputAsserter {
        return MockConsoleOutputAsserter(output: _buffer.output, testCase: testCase)
    }
    
    private class OutputBuffer: TextOutputStream {
        var output = ""
        
        func write(_ string: String) {
            output += string
        }
    }
}

/// Helper assertion class used to assert outputs of console interactions more
/// easily.
public class MockConsoleOutputAsserter {
    let output: String
    var outputIndex: String.Index
    
    let testCase: XCTestCase
    
    var didAssert = false
    
    init(output: String, testCase: XCTestCase) {
        self.output = output
        self.outputIndex = output.startIndex
        self.testCase = testCase
    }
    
    /// Asserts that from the current index, a given string can be found.
    /// After asserting successfully, the method skips the index to just after
    /// the string's end on the input buffer.
    ///
    /// - Parameter string: String to verify on the buffer
    @discardableResult
    func checkNext(_ string: String, literal: Bool = true, file: String = #file, line: Int = #line) -> MockConsoleOutputAsserter {
        if didAssert { // Ignore further asserts since first assert failed.
            return self
        }
        
        // Find next
        let range =
            output.range(of: string, options: literal ? .literal : .caseInsensitive,
                         range: outputIndex..<output.endIndex)
        
        if let range = range {
            outputIndex = range.upperBound
        } else {
            let msg = "Did not find expected string '\(string)' from current string offset."
            assert(message: msg, file: file, line: line)
        }
        
        return self
    }
    
    /// If the checking asserted, prints the entire output of the buffer being
    /// tested into the standard output for test inspection.
    func printIfAsserted(file: String = #file, line: Int = #line) {
        if didAssert {
            assert(message: output, file: file, line: line)
        }
    }
    
    private func assert(message: String, file: String, line: Int) {
        testCase.recordFailure(withDescription: message, inFile: file, atLine: line, expected: false)
        didAssert = true
    }
}