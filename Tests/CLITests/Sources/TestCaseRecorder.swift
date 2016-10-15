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
    
    func running(test: String) {
        print("Testing: ../../.build/debug/CLI \(test)".yellow)
    }
    
    func testPassed() {
        passes += 1
        
        print("Test passed".green)
    }
    
    func testFailed(with arguments: String, in type: TestRepositories.RepositoryType, expected: String, output: String?) {
        fails += 1
        
        print("TEST failed: Executing \(arguments) in \(type)".red)
        print("Expected: \"\(Optional(expected))\" -- Got: \"\(output)\"".red)
    }
    
    func end(testCase: TestCase) {
        print("Finished test case \(String(describing: type(of: testCase))): \(passes) passed tests and \(fails) failed tests".blue)
    }
    
}
