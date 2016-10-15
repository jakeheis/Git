import Rainbow

class TestCaseRecorder {
    
    static let recorder = TestCaseRecorder()
    
    var passes = 0
    var fails = 0
    
    func start(testCase: TestCase) {
        print("Starting test case \(String(describing: type(of: testCase)))".blue)
        
        passes = 0
        fails = 0
    }
    
    func running(test: String, in type: TestRepositories.RepositoryType, at location: String?) {
        var suffix = "(in \(type)"
        if let repoLocation = location {
            suffix += " at \(repoLocation)"
        }
        suffix += ")"
        print("\tTesting: ../../.build/debug/CLI \(test) \(suffix)".yellow)
    }
    
    func testPassed() {
        passes += 1
        
        print("\tTest passed".green)
    }
    
    func testFailed(with arguments: String, in type: TestRepositories.RepositoryType, expected: String, output: String?) {
        fails += 1
        
        print("\tTest failed: Executing \(arguments) in \(type)".red)
        print("\tExpected: \"\(Optional(expected))\" -- Got: \"\(output)\"".red)
    }
    
    func end(testCase: TestCase) {
        print("Finished test case \(String(describing: type(of: testCase))): \(passes) passed tests and \(fails) failed tests".blue)
    }
    
}
