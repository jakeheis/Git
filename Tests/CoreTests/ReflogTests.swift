//
//  ReflogTests.swift
//  Git
//
//  Created by Jake Heiser on 10/14/16.
//
//

import XCTest
@testable import Core

class ReflogTests: XCTestCase {
        
    func testParse() {
        let repository = TestRepositories.repository(.basic)
        
        let head = Reflog(ref: Ref(Head.name), repository: repository)
        XCTAssert(head.entries.count == 1016)
        
        XCTAssert(head.entries[1].oldHash == "f3be9f51189c34537e68df056f0cafae59d63b96")
        XCTAssert(head.entries[1].newHash == "041383a1bfc1f3ded2318db09d11b1dc8de629dd")
        XCTAssert(head.entries[1].signature == Signature(signature: "Jake Heiser <jakeheiser1@gmail.com> 1472610080 -0500"))
        XCTAssert(head.entries[1].message == "commit: Modification")
        
        let otherBranch = Reflog(ref: Ref("refs/heads/other_branch"), repository: repository)
        XCTAssert(otherBranch.entries.count == 3)
        
        XCTAssert(otherBranch.entries[1].oldHash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        XCTAssert(otherBranch.entries[1].newHash == "39f6140dee77ffed9539d61aead2e1239ac7ad13")
        XCTAssert(otherBranch.entries[1].signature == Signature(signature: "Jake Heiser <jakeheiser1@gmail.com> 1472611016 -0500"))
        XCTAssert(otherBranch.entries[1].message == "commit: Commit on other branch")
    }
    
    func testModification() {
        let repository = TestRepositories.repository(.basic)
        
        guard let reference = repository.referenceStore["other_branch"] else {
            XCTFail()
            return
        }
        
        let oldOtherBranch = Reflog(ref: reference.ref, repository: repository)
        XCTAssert(oldOtherBranch.entries.count == 3)
        
        do {
            try reference.recordUpdate(message: "test: booyah") {
                try $0.update(hash: "39f6140dee77ffed9539d61aead2e1239ac7ad13")
            }
        } catch {
            XCTFail()
        }
        
        let newOtherBranch = Reflog(ref: reference.ref, repository: repository)
        XCTAssert(newOtherBranch.entries.count == 4)
        
        XCTAssert(newOtherBranch.entries[3].oldHash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(newOtherBranch.entries[3].newHash == "39f6140dee77ffed9539d61aead2e1239ac7ad13")
        XCTAssert(newOtherBranch.entries[3].signature.name == "Jake Heiser")
        XCTAssert(newOtherBranch.entries[3].message == "test: booyah")
    }
    
}
