import Foundation
import FileKit

class AddCommandTests: TestCase {
    
    func test() {
        let location = TestRepositories.repository(.basic)
        
        try! "hello".writeToPath(location + "new.txt")
        try! "sup".writeToPath(location + "third.txt")
        try! (location + "file.txt").deleteFile()
        
        assert(executing: "status -s", in: .basic, yields: " D file.txt\n M third.txt\n?? new.txt")
        assert(executing: "add .", in: .basic, yields: "")
        assert(executing: "status -s", in: .basic, yields: "D  file.txt\nA  new.txt\nM  third.txt")
    }
    
}

class BranchCommandTests: TestCase {
    
    func test() {
        assert(executing: "branch", in: .basic, yields: "* master\n  other_branch")
        assert(executing: "branch", in: .packed, yields: "* master\n  other_branch")

        assert(executing: "branch", in: .basic, at: "other_branch", yields: "  master\n* other_branch")        
        assert(executing: "branch", in: .basic, at: "HEAD~2", yields: "* (HEAD detached at e1bb0a8)\n  master\n  other_branch")
    }
    
}

class CatFileCommandTests: TestCase {
    
    func test() {
        let commit = [
            "tree 8b94ed70009df594c0569a8a1e37a6025397b299",
            "parent e1bb0a84098498cceea87cb6b542479a4b9e769d",
            "author Jake Heiser <jakeheiser1@gmail.com> 1472615674 -0500",
            "committer Jake Heiser <jakeheiser1@gmail.com> 1472615674 -0500",
            "",
            "Many changes"
        ].joined(separator: "\n")
        assert(executing: "cat-file -t db69d97956555ed0ebf9e4a7ff4fedd8c08ba717", in: .basic, yields: "commit")
        assert(executing: "cat-file -p db69d9", in: .basic, yields: commit)

        let tree = "100644 blob 4260dd4b89d8b3f9a231538664bd3d346fdd2ead\tfile.txt\n100644 blob 234496b1caf2c7682b8441f9b866a7e2420d9748\tthird.txt"
        assert(executing: "cat-file -t 8b94ed70009df594c0569a8a1e37a6025397b299", in: .basic, yields: "tree")
        assert(executing: "cat-file -p 8b94ed70009df594c0569a8a1e37a6025397b299", in: .basic, yields: tree)
        
        assert(executing: "cat-file -t 234496b1caf2c7682b8441f9b866a7e2420d9748", in: .basic, yields: "blob")
        assert(executing: "cat-file -p 234496b1caf2c7682b8441f9b866a7e2420d9748", in: .basic, yields: "third\n")
    }
    
}

// TODO: Checkout command tests

class CommitCommandTests: TestCase {
    
    func test() {
        let location = TestRepositories.repository(.basic)
        
        try! "hello".writeToPath(location + "new.txt")
        try! "sup".writeToPath(location + "third.txt")
        try! (location + "file.txt").deleteFile()
        
        assert(executing: "add .", in: .basic, yields: "")
        assert(executing: "status -s", in: .basic, yields: "D  file.txt\nA  new.txt\nM  third.txt")
        
        // TODO: Should eventually looks like this
        // let output = [
        //     "[master 3b7298b] My commit message",
        //     " 3 files changed, 2 insertions(+), 3 deletions(-)",
        //      "delete mode 100644 file.txt",
        //     " create mode 100644 new.txt"
        // ].joined(separator: "\n")
        
        assert(executing: "commit -m \"My commit message\"", in: .basic, passesTest: { ($0 ?? "").hasSuffix("My commit message") })
    }
    
}

// TODO: CommitTree

class HashObjectCommandTests: TestCase {
    
    func test() {
        assert(executing: "hash-object file.txt", in: .emptyObjects, yields: "51f466f2e446ade0b0b2e5778ce3e0fa95e380e8")
        assert(executing: "hash-object -w second.txt", in: .emptyObjects, yields: "e019be006cf33489e2d0177a3837a2384eddebc5")
        assert(executing: "cat-file -p e019be006cf33489e2d0177a3837a2384eddebc5", in: .emptyObjects, yields: "second\n")
    }
    
}

class LsFilesCommandTests: TestCase {
    
    func test() {
        assert(executing: "ls-files", in: .basic, yields: "file.txt\nthird.txt")
    }
    
}

class LsTreeCommandTests: TestCase {
    
    func test() {
        let tree = "100644 blob 4260dd4b89d8b3f9a231538664bd3d346fdd2ead\tfile.txt\n100644 blob 234496b1caf2c7682b8441f9b866a7e2420d9748\tthird.txt"
        assert(executing: "ls-tree HEAD", in: .basic, yields: tree)
        let tree2 = "100644 blob aa3350c980eda0524c9ec6db48a613425f756b68\tfile.txt\n100644 blob 6b3b273987213e28230958801876aff0876376e7\tsecond.txt"
        assert(executing: "ls-tree 1f9bcfa09c52c0e5c7df0aa6953ffff8dffdf3c5", in: .basic, yields: tree2)
    }
    
}

class ReadTreeCommandTests: TestCase {
    
    func test() {
        assert(executing: "status -s", in: .basic, yields: "")
        assert(executing: "read-tree 1f9bcfa09c52c0e5c7df0aa6953ffff8dffdf3c5", in: .basic, yields: "")
        assert(executing: "status -s", in: .basic, yields: "MM file.txt\nAD second.txt\nD  third.txt\n?? third.txt")
    }
    
}

class ResetCommandTests: TestCase {
    
    func test() {
        let location = TestRepositories.repository(.basic)
        
        try! "hello".writeToPath(location + "new.txt")
        try! "sup".writeToPath(location + "third.txt")
        try! (location + "file.txt").deleteFile()
        
        assert(executing: "status -s", in: .basic, yields: " D file.txt\n M third.txt\n?? new.txt")
        assert(executing: "add .", in: .basic, yields: "")
        assert(executing: "status -s", in: .basic, yields: "D  file.txt\nA  new.txt\nM  third.txt")
        assert(executing: "reset .", in: .basic, yields: "")
        assert(executing: "status -s", in: .basic, yields: " D file.txt\n M third.txt\n?? new.txt")
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

class TagCommandTests: TestCase {
    
    func test() {
        assert(executing: "tag", in: .basic, yields: "0.0.1\n0.0.2\n0.0.3")
        assert(executing: "tag", in: .packed, yields: "0.0.1\n0.0.2")
    }
    
}

class UpdateIndexCommandTests: TestCase {
    
    func test() {
        let location = TestRepositories.repository(.basic)
        
        try! "hello".writeToPath(location + "new.txt")
        try! "sup".writeToPath(location + "third.txt")
        try! (location + "file.txt").deleteFile()
        
        assert(executing: "status -s", in: .basic, yields: " D file.txt\n M third.txt\n?? new.txt")
        assert(executing: "update-index --add new.txt", in: .basic, yields: "")
        assert(executing: "update-index third.txt", in: .basic, yields: "")
        assert(executing: "update-index --remove file.txt", in: .basic, yields: "")
        assert(executing: "status -s", in: .basic, yields: "D  file.txt\nA  new.txt\nM  third.txt")
    }
    
}

// TODO: UpdateRef, VerifyPack, WriteTree

let all: [TestCase] = [
    AddCommandTests(),
    BranchCommandTests(),
    CatFileCommandTests(),
    CommitCommandTests(),
    HashObjectCommandTests(),
    LsFilesCommandTests(),
    LsTreeCommandTests(),
    ReadTreeCommandTests(),
    ResetCommandTests(),
    StatusCommandTests(),
    TagCommandTests(),
    UpdateIndexCommandTests()
]

let suite: TestSuite

if ProcessInfo.processInfo.arguments.count > 1 {
    let testCase = ProcessInfo.processInfo.arguments[1]
    if let matching = all.first(where: { String(describing: type(of: $0)) == "\(testCase)CommandTests"}) {
        suite = TestSuite(testCases: [matching])
    } else {
        print("Couldn't find test case for \(testCase)".red)
        exit(1)
    }
} else {
    suite = TestSuite(testCases: all)
}

suite.test()
