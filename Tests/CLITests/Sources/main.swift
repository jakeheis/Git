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

class StatusCommandTests: TestCase {
    
    func test() {
        assert(executing: "status", in: .basic, yields: "On branch master\nnothing to commit, working directory clean")
        assert(executing: "status -s", in: .basic, yields: "")
        assert(executing: "status -sb", in: .basic, yields: "## master")
        
        executeGitCommand(with: "read-tree 1f9bcfa09c52c0e5c7df0aa6953ffff8dffdf3c5", in: .basic)
        assert(executing: "status -s", in: .basic, yields: "MM file.txt\nAD second.txt\nD  third.txt\n?? third.txt")
        assert(executing: "status -sb", in: .basic, yields: "## master\nMM file.txt\nAD second.txt\nD  third.txt\n?? third.txt")
    }
    
}

let suite = TestSuite(testCases: [
    BranchCommandTests(),
    StatusCommandTests()
])

suite.test()
