//
//  ObjectTests.swift
//  Git
//
//  Created by Jake Heiser on 8/31/16.
//
//

import XCTest
@testable import Core

class ObjectTests: XCTestCase {

    func testFileParse() {
        let commitPath = basicRepository.subpath(with: "objects/39/f6140dee77ffed9539d61aead2e1239ac7ad13")
        guard let commit = try? Commit.parse(from: commitPath, in: basicRepository) else {
            XCTFail()
            return
        }
        XCTAssert(commit.hash == "39f6140dee77ffed9539d61aead2e1239ac7ad13")
        XCTAssert(commit.type == .commit)
        
        let treePath = basicRepository.subpath(with: "objects/12/09fb65536f4ef7f72c8f87a7724074ffb5e57e")
        guard let tree = try? Tree.parse(from: treePath, in: basicRepository) else {
            XCTFail()
            return
        }
        XCTAssert(tree.hash == "1209fb65536f4ef7f72c8f87a7724074ffb5e57e")
        XCTAssert(tree.type == .tree)
    }
    
}
