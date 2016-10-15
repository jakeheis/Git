import Foundation
import FileKit

class BranchCommandTests: TestCase {
    
    func test() {
        assert(executing: "branch", in: .basic, yields: "* master\n  other_branch")
        assert(executing: "branch", in: .packed, yields: "* master\n  other_branch")

        assert(executing: "branch", in: .basic, at: "other_branch", yields: "  master\n* other_branch")        
        assert(executing: "branch", in: .basic, at: "HEAD~2", yields: "* (HEAD detached at e1bb0a8)\n  master\n  other_branch")
    }
    
}

let suite = TestSuite(testCases: [
    BranchCommandTests()
])

suite.test()
