//
//  ReferenceStoreTests.swift
//  Git
//
//  Created by Jake Heiser on 10/15/16.
//
//

import XCTest
@testable import Core

class ReferenceStoreTests: XCTestCase {
  
    func testNonstrictParse() {
        let repository = TestRepositories.repository(.basic)
        
        guard let headRef = repository.referenceStore["HEAD"] else {
            XCTFail()
            return
        }
        XCTAssert(headRef.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        guard let masterRef1 = repository.referenceStore["master"],
            let masterRef2 = repository.referenceStore["refs/heads/master"] else {
                XCTFail()
                return
        }
        XCTAssert(masterRef1.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        XCTAssert(masterRef2.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        guard let tagRef1 = repository.referenceStore["0.0.2"],
            let tagRef2 = repository.referenceStore["refs/tags/0.0.2"] else {
                XCTFail()
                return
        }
        XCTAssert(tagRef1.equals(ref: "refs/tags/0.0.2", hash: "e1bb0a84098498cceea87cb6b542479a4b9e769d"))
        XCTAssert(tagRef2.equals(ref: "refs/tags/0.0.2", hash: "e1bb0a84098498cceea87cb6b542479a4b9e769d"))
    }
    
    func testPackedNonstrictParse() {
        let repository = TestRepositories.repository(.packed)
        
        guard let headRef = repository.referenceStore["HEAD"] else {
            XCTFail()
            return
        }
        XCTAssert(headRef.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        guard let masterRef1 = repository.referenceStore["master"],
            let masterRef2 = repository.referenceStore["refs/heads/master"] else {
                XCTFail()
                return
        }
        XCTAssert(masterRef1.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        XCTAssert(masterRef2.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        guard let tagRef1 = repository.referenceStore["0.0.2"],
            let tagRef2 = repository.referenceStore["refs/tags/0.0.2"] else {
                XCTFail()
                return
        }
        XCTAssert(tagRef1.equals(ref: "refs/tags/0.0.2", hash: "e1bb0a84098498cceea87cb6b542479a4b9e769d"))
        XCTAssert(tagRef2.equals(ref: "refs/tags/0.0.2", hash: "e1bb0a84098498cceea87cb6b542479a4b9e769d"))
    }
    
    func testStrictParse() {
        let repository = TestRepositories.repository(.basic)
        
        guard let headRef = repository.referenceStore.reference(matching: Ref("HEAD"), strict: true) else {
            XCTFail()
            return
        }
        XCTAssert(headRef.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        XCTAssert(repository.referenceStore.reference(matching: Ref("master"), strict: true) == nil)
        guard let masterRef = repository.referenceStore.reference(matching: Ref("refs/heads/master"), strict: true) else {
            XCTFail()
            return
        }
        XCTAssert(masterRef.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        XCTAssert(repository.referenceStore.reference(matching: Ref("0.0.2"), strict: true) == nil)
        guard let tagRef = repository.referenceStore.reference(matching: Ref("refs/tags/0.0.2"), strict: true) else {
            XCTFail()
            return
        }
        XCTAssert(tagRef.equals(ref: "refs/tags/0.0.2", hash: "e1bb0a84098498cceea87cb6b542479a4b9e769d"))
    }
    
    func testStrictPackedParse() {
        let repository = TestRepositories.repository(.packed)
        
        guard let headRef = repository.referenceStore.reference(matching: Ref("HEAD"), strict: true) else {
            XCTFail()
            return
        }
        XCTAssert(headRef.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        XCTAssert(repository.referenceStore.reference(matching: Ref("master"), strict: true) == nil)
        guard let masterRef = repository.referenceStore.reference(matching: Ref("refs/heads/master"), strict: true) else {
            XCTFail()
            return
        }
        XCTAssert(masterRef.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        XCTAssert(repository.referenceStore.reference(matching: Ref("0.0.2"), strict: true) == nil)
        guard let tagRef = repository.referenceStore.reference(matching: Ref("refs/tags/0.0.2"), strict: true) else {
            XCTFail()
            return
        }
        XCTAssert(tagRef.equals(ref: "refs/tags/0.0.2", hash: "e1bb0a84098498cceea87cb6b542479a4b9e769d"))
    }
    
}
