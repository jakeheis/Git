//
//  HeadTests.swift
//  Git
//
//  Created by Jake Heiser on 8/31/16.
//
//

import XCTest
@testable import Core

class HeadTests: GitTestCase {

    func testHashHead() {
        let repository = TestRepositories.repository(.basic, at: "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        
        guard case let .simple(simple) = repository.head!.kind else {
            XCTFail()
            return
        }
        XCTAssert(simple.hash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
    }
    
    func testRefHead() {
        let unpackedRepository = TestRepositories.repository(.basic, at: "other_branch")
        let packedRepository = TestRepositories.repository(.packed, at: "other_branch")
        
        guard case let .symbolic(reference) = unpackedRepository.head!.kind else {
            XCTFail()
            return
        }
        XCTAssert(reference.dereferenced.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(reference.dereferenced.ref == "refs/heads/other_branch")
        XCTAssert(reference.dereferenced.name == "other_branch")
        
        guard case let .symbolic(packedReference) = packedRepository.head!.kind else {
            XCTFail()
            return
        }
        XCTAssert(packedReference.dereferenced.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(packedReference.dereferenced.ref == "refs/heads/other_branch")
        XCTAssert(packedReference.dereferenced.name == "other_branch")
    }
    
    func testUpdate() {
        let repository = TestRepositories.repository(.basic)
        
        guard let headRef = Head(repository: repository) else {
            XCTFail()
            return
        }
        
        guard case let .symbolic(ref) = headRef.kind else {
            XCTFail()
            return
        }
        XCTAssert(ref.dereferenced.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        do {
            try headRef.update(to: "e1bb0a84098498cceea87cb6b542479a4b9e769d", message: nil)
        } catch {
            XCTFail()
        }
        
        // Make sure old object correctly updated
        
        guard case let .simple(reference) = headRef.kind else {
            XCTFail()
            return
        }
        XCTAssert(reference.hash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        
        // Make sure written correctly
        
        guard let newHead = Head(repository: repository) else {
            XCTFail()
            return
        }
        
        guard case let .simple(new) = newHead.kind else {
            XCTFail()
            return
        }
        XCTAssert(new.hash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
    }

}
