import Foundation
import FileKit

class BranchCommandTests: TestCase {
    
    func test() {
        assert(executing: "branch", in: .basic, yields: "* master\n  other_branch")
    }
    
}

let suite = TestSuite(testCases: [
    BranchCommandTests()
])

suite.test()
