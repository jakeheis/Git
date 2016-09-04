//
//  TreeTests.swift
//  Git
//
//  Created by Jake Heiser on 8/30/16.
//
//

import XCTest
@testable import Core
import FileKit

class TreeTests: XCTestCase {

    func testParse() {
        let firstPath = basicRepository.subpath(with: "objects/12/09fb65536f4ef7f72c8f87a7724074ffb5e57e")
        guard let firstTree = try? Tree.parse(from: firstPath, in: basicRepository) else {
            XCTFail()
            return
        }
        
        XCTAssert(firstTree.hash == "1209fb65536f4ef7f72c8f87a7724074ffb5e57e")
        XCTAssert(firstTree.treeEntries[0].equals(mode: .blob, hash: "aa3350c980eda0524c9ec6db48a613425f756b68", name: "file.txt"))
        XCTAssert(firstTree.treeEntries[1].equals(mode: .blob, hash: "1c59427adc4b205a270d8f810310394962e79a8b", name: "second.txt"))
        
        let secondPath = basicRepository.subpath(with: "objects/1f/1ace28d590693be994c10b3c2895cb62da6229")
        guard let secondTree = try? Tree.parse(from: secondPath, in: basicRepository) else {
            XCTFail()
            return
        }
        
        XCTAssert(secondTree.hash == "1f1ace28d590693be994c10b3c2895cb62da6229")
        XCTAssert(secondTree.treeEntries[0].equals(mode: .directory, hash: "5e5176fa30d950855ef3a9b9050111328b968971", name: "Subdirectory"))
        XCTAssert(secondTree.treeEntries[1].equals(mode: .blob, hash: "aa3350c980eda0524c9ec6db48a613425f756b68", name: "file.txt"))
        XCTAssert(secondTree.treeEntries[2].equals(mode: .blob, hash: "e20f5916c1cb235a7f26cd91e09a40e277d38306", name: "other_file.txt"))
        XCTAssert(secondTree.treeEntries[3].equals(mode: .blob, hash: "6b3b273987213e28230958801876aff0876376e7", name: "second.txt"))
    }

}
