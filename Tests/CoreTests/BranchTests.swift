//
//  BranchTests.swift
//  Git
//
//  Created by Jake Heiser on 8/30/16.
//
//

import XCTest
@testable import Core

class BranchTests: XCTestCase {

    func testRepositoryTags() {
        XCTAssert(testRepository.branches.count == 2)
        
        XCTAssert(testRepository.branches[0].name == "master")
        XCTAssert(testRepository.branches[1].name == "other_branch")
    }
    
    func testParse() {
        let firstBranch = testRepository.branches[0]
        XCTAssert(firstBranch.ref == "refs/heads/master")
        XCTAssert(firstBranch.hash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        
        let secondBranch = testRepository.branches[1]
        XCTAssert(secondBranch.ref == "refs/heads/other_branch")
        XCTAssert(secondBranch.hash == "39f6140dee77ffed9539d61aead2e1239ac7ad13")
    }
    
    func testObjectRetrieval() {
        let firstBranch = testRepository.branches[0]
        let firstBranchCommit = firstBranch.object as! Commit
        
        XCTAssert(firstBranchCommit.hash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        
        let secondBranch = testRepository.branches[1]
        let secondBranchCommit = secondBranch.object as! Commit
        
        XCTAssert(secondBranchCommit.hash == "39f6140dee77ffed9539d61aead2e1239ac7ad13")
    }

}
