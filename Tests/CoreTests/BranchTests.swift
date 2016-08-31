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
        XCTAssert(basicRepository.branches.count == 2)
        
        XCTAssert(basicRepository.branches[0].name == "master")
        XCTAssert(basicRepository.branches[1].name == "other_branch")
    }
    
    func testParse() {
        let secondBranch = basicRepository.branches[1]
        XCTAssert(secondBranch.ref == "refs/heads/other_branch")
        XCTAssert(secondBranch.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
    }
    
    func testPackedBranches() {
        XCTAssert(packedRepository.branches.count == 2)
        
        let secondBranch = packedRepository.branches[1]
        XCTAssert(secondBranch.name == "other_branch")
        XCTAssert(secondBranch.ref == "refs/heads/other_branch")
        XCTAssert(secondBranch.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
    }
    
    func testHeadReference() {
        guard case let .reference(reference) = basicRepository.head!.kind else {
            XCTFail()
            return
        }
        XCTAssert(reference.hash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        
        guard case let .reference(packedReference) = packedRepository.head!.kind else {
            XCTFail()
            return
        }
        XCTAssert(packedReference.hash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
    }

}
