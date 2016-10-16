import Foundation
import FileKit

class TestSuite {
    
    let testCases: [TestCase]
    
    init(testCases: [TestCase]) {
        self.testCases = testCases
    }
    
    func test() {
        for testCase in testCases {
            testCase.privateTest()
        }
    }
    
}

protocol TestCase {    
    func test()
}

extension TestCase {
    
    fileprivate func privateTest() {
        TestCaseRecorder.recorder.start(testCase: self)
        test()
        TestCaseRecorder.recorder.end(testCase: self)
        reset()
    }
    
    @discardableResult
    func assert(executing arguments: String, in type: TestRepositories.RepositoryType, at location: String? = nil, yields expected: String) -> Bool {
        TestCaseRecorder.recorder.running(test: arguments, in: type, at: location)
        
        if let repoLocation = location {
            executeGitCommand(with: "checkout -q \(repoLocation)", in: type)
        }
        
        let output = execute(with: arguments, in: type)
        if output == expected {
            TestCaseRecorder.recorder.testPassed()
            return true
        }
        TestCaseRecorder.recorder.testFailed(with: arguments, in: type, expected: expected, output: output)
        return false
    }
    
    func execute(with arguments: String, in type: TestRepositories.RepositoryType) -> String? {
        let path = TestRepositories.repository(type)
        
        let output = Pipe()
        
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", (Path.Current + "../../.build/debug/CLI").rawValue + " \(arguments)"]
        process.currentDirectoryPath = path.rawValue
        process.standardOutput = output
        process.launch()
        process.waitUntilExit()
        
        if let str = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) {
            if str.isEmpty {
                return str
            }
            return str.substring(to: str.index(before: str.endIndex)) // Remove ending newline
        }
        
        return nil
    }
    
    func executeGitCommand(with arguments: String, in type: TestRepositories.RepositoryType) {
        let path = TestRepositories.repository(type)
        
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "git \(arguments)"]
        process.currentDirectoryPath = path.rawValue
        process.launch()
        process.waitUntilExit()
    }
    
    func reset() {
        TestRepositories.reset()
    }
    
}
