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
        XCTAssert(secondBranch.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
    }

}
