//
//  AnnotatedTagTests.swift
//  Git
//
//  Created by Jake Heiser on 8/31/16.
//
//

import XCTest
@testable import Core
import FileKit

class AnnotatedTagTests: XCTestCase {

    func testParse() {
        let firstPath = basicRepository.subpath(with: "objects/b1/cab66f094cc38fe71fdc425de075851e69bee2")
        guard let tag = try? AnnotatedTag.parse(from: firstPath, in: basicRepository) else {
            XCTFail()
            return
        }
        
        XCTAssert(tag.hash == "b1cab66f094cc38fe71fdc425de075851e69bee2")
        XCTAssert(tag.objectHash == "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        XCTAssert(tag.tagType == .commit)
        XCTAssert(tag.name == "0.0.3")
        XCTAssert(tag.message == "First annotated tag")
    }

}
