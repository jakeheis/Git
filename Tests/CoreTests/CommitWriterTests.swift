//
//  CommitWriterTests.swift
//  Git
//
//  Created by Jake Heiser on 9/9/16.
//
//

import XCTest
@testable import Core

class CommitWriterTests: XCTestCase {

    func testWrite() {
        let repository = TestRepositories.repository(.emptyObjects)
        
        let treeHash = "8b94ed70009df594c0569a8a1e37a6025397b299"
        let parentHash = "e1bb0a84098498cceea87cb6b542479a4b9e769d"
        let message = "Many changes"
        
        let hash: String
        do {
            hash = try CommitWriter(treeHash: treeHash, parentHash: parentHash, message: message, repository: repository, time: Date(timeIntervalSince1970: 1472615674)).write()
        } catch {
            XCTFail()
            return
        }
        
        XCTAssert(hash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        
        let writtenCommit = repository.objectStore[hash] as! Commit
        XCTAssert(writtenCommit.hash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        XCTAssert(writtenCommit.treeHash == "8b94ed70009df594c0569a8a1e37a6025397b299")
        XCTAssert(writtenCommit.parentHash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        XCTAssert(writtenCommit.message == message)
        
        XCTAssert(writtenCommit.authorSignature.name == "Jake Heiser")
        XCTAssert(writtenCommit.authorSignature.email == "jakeheiser1@gmail.com")
        XCTAssert(writtenCommit.authorSignature.timeZone.secondsFromGMT() == TimeZone.current.secondsFromGMT())
        
        XCTAssert(writtenCommit.committerSignature.name == "Jake Heiser")
        XCTAssert(writtenCommit.committerSignature.email == "jakeheiser1@gmail.com")
        XCTAssert(writtenCommit.committerSignature.timeZone.secondsFromGMT() == TimeZone.current.secondsFromGMT())
    }

}
