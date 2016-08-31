//
//  TagTests.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

import XCTest
@testable import Core
import FileKit

//let testRepository = Repository(path: Path.Current + "Tests/Repositories/Basic")!
let testRepository = Repository(path: "/Users/jakeheiser/Documents/Swift/Git/Tests/Repositories/Basic")!


class TagTests: XCTestCase {
    
    func testRepositoryTags() {
        XCTAssert(testRepository.tags.count == 2)
        
        XCTAssert(testRepository.tags[0].name == "0.0.1")
        XCTAssert(testRepository.tags[1].name == "0.0.2")
    }
    
    func testParse() {
        let firstTag = testRepository.tags[0]
        XCTAssert(firstTag.ref == "refs/tags/0.0.1")
        XCTAssert(firstTag.hash == "041383a1bfc1f3ded2318db09d11b1dc8de629dd")
        
        let secondTag = testRepository.tags[1]
        XCTAssert(secondTag.ref == "refs/tags/0.0.2")
        XCTAssert(secondTag.hash == "e1bb0a84098498cceea87cb6b542479a4b9e769d")
    }
    
}
