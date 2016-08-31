//
//  CommitTests.swift
//  Git
//
//  Created by Jake Heiser on 8/30/16.
//
//

import XCTest
@testable import Core
import FileKit

class CommitTests: XCTestCase {

    func testParse() {
        let firstPath = testRepository.subpath(with: "objects/39/f6140dee77ffed9539d61aead2e1239ac7ad13")
        let firstCommit = try! Object.from(file: firstPath, in: testRepository) as! Commit
        
        XCTAssert(firstCommit.hash == "39f6140dee77ffed9539d61aead2e1239ac7ad13")
        XCTAssert(firstCommit.treeHash == "11bbaed2e1c68b714e12e35615aedbe3c2a4e760")
        XCTAssert(firstCommit.parentHash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        XCTAssert(firstCommit.message == "Commit on other branch")
        
        let secondPath = testRepository.subpath(with: "objects/94/e72a122b9099798132e971eaccf727c1ff037d")
        let secondCommit = try! Object.from(file: secondPath, in: testRepository) as! Commit
        
        XCTAssert(secondCommit.hash == "94e72a122b9099798132e971eaccf727c1ff037d")
        XCTAssert(secondCommit.treeHash == "1209fb65536f4ef7f72c8f87a7724074ffb5e57e")
        XCTAssert(secondCommit.parentHash == "041383a1bfc1f3ded2318db09d11b1dc8de629dd")
        XCTAssert(secondCommit.message == "Added second file")
    }

}
