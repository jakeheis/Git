//
//  BlobTests.swift
//  Git
//
//  Created by Jake Heiser on 8/30/16.
//
//

import XCTest
@testable import Core
import FileKit

class BlobTests: XCTestCase {

    func testParse() {
        let firstPath = basicRepository.subpath(with: "objects/aa/3350c980eda0524c9ec6db48a613425f756b68")
        guard let firstBlob = try? Blob.parse(from: firstPath, in: basicRepository) else {
            XCTFail()
            return
        }
        
        XCTAssert(firstBlob.hash == "aa3350c980eda0524c9ec6db48a613425f756b68")
        XCTAssert(String(data: firstBlob.data, encoding: .utf8) == "File\nmodification\n")
        
        let secondPath = basicRepository.subpath(with: "objects/e2/0f5916c1cb235a7f26cd91e09a40e277d38306")
        guard let secondBlob = try? Blob.parse(from: secondPath, in: basicRepository) else {
            XCTFail()
            return
        }
        
        XCTAssert(secondBlob.hash == "e20f5916c1cb235a7f26cd91e09a40e277d38306")
        XCTAssert(String(data: secondBlob.data, encoding: .utf8) == "other file in other branch\n")
    }
    
    func testCreation() {
        guard let blob = Blob.formBlob(from: basicRepository.path + "third.txt", in: basicRepository) else {
            XCTFail()
            return
        }
        XCTAssert(blob.hash == "234496b1caf2c7682b8441f9b866a7e2420d9748")
    }

}
