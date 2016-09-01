//
//  HeadTests.swift
//  Git
//
//  Created by Jake Heiser on 8/31/16.
//
//

import XCTest
@testable import Core

class HeadTests: XCTestCase {

    func testHashHead() {
        basicRepository.checkout("e1bb0a84098498cceea87cb6b542479a4b9e769d") { 
            guard case let .hash(hash) = basicRepository.head!.kind else {
                XCTFail()
                return
            }
            XCTAssert(hash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        }
    }
    
    func testRefHead() {
        basicRepository.checkout("other_branch") {
            guard case let .reference(reference) = basicRepository.head!.kind else {
                XCTFail()
                return
            }
            XCTAssert(reference.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
            XCTAssert(reference.ref == "refs/heads/other_branch")
            XCTAssert(reference.name == "other_branch")
        }
        
        packedRepository.checkout("other_branch") {
            guard case let .reference(packedReference) = packedRepository.head!.kind else {
                XCTFail()
                return
            }
            XCTAssert(packedReference.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
            XCTAssert(packedReference.ref == "refs/heads/other_branch")
            XCTAssert(packedReference.name == "other_branch")
        }
    }

}
