//
//  CommitWriterTests.swift
//  Git
//
//  Created by Jake Heiser on 9/9/16.
//
//

import XCTest
@testable import Core
import FileKit

class CommitWriterTests: XCTestCase {

    func testWrite() {
        let repository = TestRepositories.repository(.emptyObjects)
        
        let treeHash = "8b94ed70009df594c0569a8a1e37a6025397b299"
        let parentHash = "e1bb0a84098498cceea87cb6b542479a4b9e769d"
        let message = "Many changes"
        
        let hash: String
        do {
            hash = try CommitWriter(treeHash: treeHash, parentHash: parentHash, message: message, repository: repository, time: Date(timeIntervalSince1970: 1472615674), timeZone: TimeZone(abbreviation: "CST")).write()
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
        XCTAssert(writtenCommit.authorSignature.timeZone.secondsFromGMT() == TimeZone(abbreviation: "CST")!.secondsFromGMT())
        
        XCTAssert(writtenCommit.committerSignature.name == "Jake Heiser")
        XCTAssert(writtenCommit.committerSignature.email == "jakeheiser1@gmail.com")
        XCTAssert(writtenCommit.committerSignature.timeZone.secondsFromGMT() == TimeZone(abbreviation: "CST")!.secondsFromGMT())
    }
    
    func testCommitCurrent() {
        let repository = TestRepositories.repository(.basic)
        guard let index = repository.index else {
            XCTFail()
            return
        }
        
        try! "hi".writeToPath(repository.path + "hi.txt")
        try! (repository.path + "third.txt").deleteFile()
        try! "overwritten".writeToPath(repository.path + "file.txt")
        
        let message = "A test commmit"
        let hash: String
        do {
            try index.modify(with: ".")
            hash = try CommitWriter.commitCurrent(in: repository, message: message)
        } catch {
            XCTFail()
            return
        }
        
        // Ensure commit is correctly made
        
        guard let commit = repository.head?.commit else {
            XCTFail()
            return
        }
        
        XCTAssert(commit.hash == hash)
        XCTAssert(commit.parentHash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        XCTAssert(commit.message == message)
        
        XCTAssert(commit.authorSignature.name == "Jake Heiser")
        XCTAssert(commit.authorSignature.email == "jakeheiser1@gmail.com")
        XCTAssert(commit.authorSignature.timeZone.secondsFromGMT() == TimeZone(abbreviation: "PST")!.secondsFromGMT())
        
        XCTAssert(commit.committerSignature.name == "Jake Heiser")
        XCTAssert(commit.committerSignature.email == "jakeheiser1@gmail.com")
        XCTAssert(commit.committerSignature.timeZone.secondsFromGMT() == TimeZone(abbreviation: "PST")!.secondsFromGMT())
        
        // Ensure reflogs are updated
        
        let headLog = Reflog(ref: "HEAD", repository: repository)
        guard let headEntry = headLog.entries.last else {
            XCTFail()
            return
        }
        XCTAssert(headEntry.message == "commit: \(message)")
        XCTAssert(headEntry.oldHash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        XCTAssert(headEntry.newHash == hash)
        XCTAssert(headEntry.signature.name == "Jake Heiser")
        
        let log = Reflog(ref: "refs/heads/master", repository: repository)
        guard let entry = log.entries.last else {
            XCTFail()
            return
        }
        XCTAssert(entry.message == "commit: \(message)")
        XCTAssert(entry.oldHash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        XCTAssert(entry.newHash == hash)
        XCTAssert(entry.signature.name == "Jake Heiser")
        
        // Ensure no longer any changes
        
        XCTAssert(index.stagedChanges()?.deltaFiles.count == 0)
        XCTAssert(index.unstagedChanges().deltaFiles.count == 0)
    }

}
