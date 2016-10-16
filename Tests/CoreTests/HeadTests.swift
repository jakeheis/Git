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

    func testSimpleHead() {
        let repository = TestRepositories.repository(.basic, at: "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        
        guard case let .simple(simple) = repository.head!.kind else {
            XCTFail()
            return
        }
        XCTAssert(simple.hash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        XCTAssert(simple.ref == "HEAD")
        XCTAssert(simple.name == "HEAD")
    }
    
    func testSymbolicHead() {
        let unpackedRepository = TestRepositories.repository(.basic, at: "other_branch")
        let packedRepository = TestRepositories.repository(.packed, at: "other_branch")
        
        guard case let .symbolic(reference) = unpackedRepository.head!.kind else {
            XCTFail()
            return
        }
        XCTAssert(reference.ref == "HEAD")
        XCTAssert(reference.dereferenced.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(reference.dereferenced.ref == "refs/heads/other_branch")
        XCTAssert(reference.dereferenced.name == "other_branch")
        
        guard case let .symbolic(packedReference) = packedRepository.head!.kind else {
            XCTFail()
            return
        }
        XCTAssert(packedReference.ref == "HEAD")
        XCTAssert(packedReference.dereferenced.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(packedReference.dereferenced.ref == "refs/heads/other_branch")
        XCTAssert(packedReference.dereferenced.name == "other_branch")
    }
    
    func testUnderlyingUpdate() {
        let repository = TestRepositories.repository(.basic)
        
        guard let headRef = Head(repository: repository) else {
            XCTFail()
            return
        }
        
        guard case let .symbolic(reference) = headRef.kind else {
            XCTFail()
            return
        }
        XCTAssert(reference.ref == "HEAD")
        XCTAssert(reference.dereferenced.hash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        XCTAssert(reference.dereferenced.ref == "refs/heads/master")
        XCTAssert(reference.dereferenced.name == "master")
        
        let message = "something: My update mssage"
        do {
            try headRef.updateUnderlying(to: "e1bb0a84098498cceea87cb6b542479a4b9e769d", message: message)
        } catch {
            XCTFail()
        }
        
        guard case let .symbolic(new) = headRef.kind else {
            XCTFail()
            return
        }
        XCTAssert(new.ref == "HEAD")
        XCTAssert(new.dereferenced.hash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        XCTAssert(new.dereferenced.ref == "refs/heads/master")
        XCTAssert(new.dereferenced.name == "master")
        
        let headLog = Reflog(ref: new.ref, repository: repository)
        let masterLog = Reflog(ref: new.dereferenced.ref, repository: repository)
        guard let headEntry = headLog.entries.last, let masterEntry = masterLog.entries.last else {
            XCTFail()
            return
        }
        
        XCTAssert(headEntry.oldHash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        XCTAssert(headEntry.newHash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        XCTAssert(headEntry.message == message)
        XCTAssert(headEntry.signature.name == "Jake Heiser")
        
        XCTAssert(masterEntry.oldHash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        XCTAssert(masterEntry.newHash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        XCTAssert(masterEntry.message == message)
        XCTAssert(masterEntry.signature.name == "Jake Heiser")
    }
    
    func testUpdateToSimple() {
        let repository = TestRepositories.repository(.basic)
        
        guard let headRef = Head(repository: repository) else {
            XCTFail()
            return
        }
        
        guard case let .symbolic(reference) = headRef.kind else {
            XCTFail()
            return
        }
        XCTAssert(reference.ref == "HEAD")
        XCTAssert(reference.dereferenced.hash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        XCTAssert(reference.dereferenced.ref == "refs/heads/master")
        XCTAssert(reference.dereferenced.name == "master")
        
        let message = "something: My update mssage"
        do {
            try headRef.update(toSimple: "e1bb0a84098498cceea87cb6b542479a4b9e769d", message: message)
        } catch {
            XCTFail()
        }
        
        guard case let .simple(new) = headRef.kind else {
            XCTFail()
            return
        }
        XCTAssert(new.hash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        XCTAssert(new.ref == "HEAD")
        XCTAssert(new.name == "HEAD")
        
        let headLog = Reflog(ref: new.ref, repository: repository)
        guard let headEntry = headLog.entries.last else {
            XCTFail()
            return
        }
        XCTAssert(headEntry.oldHash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        XCTAssert(headEntry.newHash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        XCTAssert(headEntry.message == message)
        XCTAssert(headEntry.signature.name == "Jake Heiser")
        
        guard let written = repository.head, case let .simple(writtenSimple) = written.kind else {
            XCTFail()
            return
        }
        XCTAssert(writtenSimple.hash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        XCTAssert(writtenSimple.ref == "HEAD")
        XCTAssert(writtenSimple.name == "HEAD")
    }
    
    func testUpdateToSymbolic() {
        let repository = TestRepositories.repository(.basic, at: "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        
        guard let headRef = Head(repository: repository), let newDestination = repository.referenceStore["refs/heads/other_branch"] else {
            XCTFail()
            return
        }
        
        guard case let .simple(old) = headRef.kind else {
            XCTFail()
            return
        }
        XCTAssert(old.hash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        XCTAssert(old.ref == "HEAD")
        XCTAssert(old.name == "HEAD")
        
        let message = "something: My update mssage"
        do {
            try headRef.update(toSymbolic: newDestination, message: message)
        } catch {
            XCTFail()
        }
        
        guard case let .symbolic(new) = headRef.kind else {
            XCTFail()
            return
        }
        XCTAssert(new.ref == "HEAD")
        XCTAssert(new.dereferenced.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(new.dereferenced.ref == "refs/heads/other_branch")
        XCTAssert(new.dereferenced.name == "other_branch")
        
        let headLog = Reflog(ref: new.ref, repository: repository)
        guard let headEntry = headLog.entries.last else {
            XCTFail()
            return
        }
        XCTAssert(headEntry.oldHash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
        XCTAssert(headEntry.newHash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(headEntry.message == message)
        XCTAssert(headEntry.signature.name == "Jake Heiser")
        
        guard let written = repository.head, case let .symbolic(writtenSymbolic) = written.kind else {
            XCTFail()
            return
        }
        XCTAssert(writtenSymbolic.ref == "HEAD")
        XCTAssert(writtenSymbolic.dereferenced.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(writtenSymbolic.dereferenced.ref == "refs/heads/other_branch")
        XCTAssert(writtenSymbolic.dereferenced.name == "other_branch")
    }

}
