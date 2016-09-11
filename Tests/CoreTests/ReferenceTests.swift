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
        
        guard let headRef = ReferenceParser.parse(raw: "HEAD", repository: repository) as? Head else {
            XCTFail()
            return
        }
        XCTAssert(headRef.equals(ref: "HEAD", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        XCTAssert(headRef.dereferenced.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        guard let masterRef1 = ReferenceParser.parse(raw: "master", repository: repository) as? Branch,
            let masterRef2 = ReferenceParser.parse(raw: "refs/heads/master", repository: repository) as? Branch else {
                XCTFail()
                return
        }
        XCTAssert(masterRef1.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        XCTAssert(masterRef2.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        guard let tagRef1 = ReferenceParser.parse(raw: "0.0.2", repository: repository) as? Tag,
            let tagRef2 = ReferenceParser.parse(raw: "refs/tags/0.0.2", repository: repository) as? Tag else {
                XCTFail()
                return
        }
        XCTAssert(tagRef1.equals(ref: "refs/tags/0.0.2", hash: "e1bb0a84098498cceea87cb6b542479a4b9e769d"))
        XCTAssert(tagRef2.equals(ref: "refs/tags/0.0.2", hash: "e1bb0a84098498cceea87cb6b542479a4b9e769d"))
    }
    
    func testPackedRawParse() {
        let repository = TestRepositories.repository(.packed)
        
        guard let headRef = ReferenceParser.parse(raw: "HEAD", repository: repository) as? Head else {
            XCTFail()
            return
        }
        XCTAssert(headRef.equals(ref: "HEAD", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        XCTAssert(headRef.dereferenced.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        guard let masterRef1 = ReferenceParser.parse(raw: "master", repository: repository) as? Branch,
            let masterRef2 = ReferenceParser.parse(raw: "refs/heads/master", repository: repository) as? Branch else {
                XCTFail()
                return
        }
        XCTAssert(masterRef1.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        XCTAssert(masterRef2.equals(ref: "refs/heads/master", hash: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717"))
        
        guard let tagRef1 = ReferenceParser.parse(raw: "0.0.2", repository: repository) as? Tag,
            let tagRef2 = ReferenceParser.parse(raw: "refs/tags/0.0.2", repository: repository) as? Tag else {
                XCTFail()
                return
        }
        XCTAssert(tagRef1.equals(ref: "refs/tags/0.0.2", hash: "e1bb0a84098498cceea87cb6b542479a4b9e769d"))
        XCTAssert(tagRef2.equals(ref: "refs/tags/0.0.2", hash: "e1bb0a84098498cceea87cb6b542479a4b9e769d"))
    }
    
}
