//
//  BranchTests.swift
//  Git
//
//  Created by Jake Heiser on 8/30/16.
//
//

import XCTest
@testable import Core

class BranchTests: GitTestCase {

    func testRepositoryTags() {
        let repository = TestRepositories.repository(.basic)
        
        XCTAssert(repository.branches.count == 2)
        
        XCTAssert(repository.branches[0].name == "master")
        XCTAssert(repository.branches[1].name == "other_branch")
    }
    
    func testParse() {
        let repository = TestRepositories.repository(.basic)
        
        let secondBranch = repository.branches[1]
        XCTAssert(secondBranch.ref == "refs/heads/other_branch")
        XCTAssert(secondBranch.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
    }
    
    func testPackedBranches() {
        let repository = TestRepositories.repository(.packed)
        
        XCTAssert(repository.branches.count == 2)
        
        let secondBranch = repository.branches[1]
        XCTAssert(secondBranch.name == "other_branch")
        XCTAssert(secondBranch.ref == "refs/heads/other_branch")
        XCTAssert(secondBranch.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
    }
    
    func testWrite() {
        let repository = TestRepositories.repository(.basic)
        
        let new = Branch(ref: "refs/heads/new_branch", hash: "29287d7a61db5b55e66f707a01b7fb4b11efcb40", repository: repository)
        do {
            try new.write()
        } catch {
            XCTFail()
        }
        
        guard let read = ReferenceParser.from(ref: "refs/heads/new_branch", repository: repository) as? Branch else {
            XCTFail()
            return
        }
        
        XCTAssert(read.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(read.ref == "refs/heads/new_branch")
    }
    
    func testUpdate() {
        let repository = TestRepositories.repository(.basic)
        guard let initial = ReferenceParser.from(ref: "refs/heads/master", repository: repository) as? Branch else {
            XCTFail()
            return
        }
        
        do {
            try initial.update(hash: "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        } catch {
            XCTFail()
        }
        
        guard let new = ReferenceParser.from(ref: "refs/heads/master", repository: repository) as? Branch else {
            XCTFail()
            return
        }
        
        XCTAssert(new.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(new.ref == "refs/heads/master")
    }

}
