//
//  ReferenceTests.swift
//  Git
//
//  Created by Jake Heiser on 9/11/16.
//
//

import XCTest
@testable import Core

class ReferenceTests: XCTestCase {

    func testRawParse() {
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
    
    func testPackedRawParse() {
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
    
}
