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
        let firstPath = testRepository.subpath(with: "objects/12/09fb65536f4ef7f72c8f87a7724074ffb5e57e")
        let firstTree = try! Object.from(file: firstPath, in: testRepository) as! Tree
        
        XCTAssert(firstTree.hash == "1209fb65536f4ef7f72c8f87a7724074ffb5e57e")
        XCTAssert(firstTree.treeEntries[0].equals(TreeEntry(mode: .blob, hash: "aa3350c980eda0524c9ec6db48a613425f756b68", name: "file.txt", repository: testRepository)))
        XCTAssert(firstTree.treeEntries[1].equals(TreeEntry(mode: .blob, hash: "1c59427adc4b205a270d8f810310394962e79a8b", name: "second.txt", repository: testRepository)))
        
        let secondPath = testRepository.subpath(with: "objects/1f/1ace28d590693be994c10b3c2895cb62da6229")
        let secondTree = try! Object.from(file: secondPath, in: testRepository) as! Tree
        
        XCTAssert(secondTree.hash == "1f1ace28d590693be994c10b3c2895cb62da6229")
        XCTAssert(secondTree.treeEntries[0].equals(TreeEntry(mode: .directory, hash: "5e5176fa30d950855ef3a9b9050111328b968971", name: "Subdirectory", repository: testRepository)))
        XCTAssert(secondTree.treeEntries[1].equals(TreeEntry(mode: .blob, hash: "aa3350c980eda0524c9ec6db48a613425f756b68", name: "file.txt", repository: testRepository)))
        XCTAssert(secondTree.treeEntries[2].equals(TreeEntry(mode: .blob, hash: "e20f5916c1cb235a7f26cd91e09a40e277d38306", name: "other_file.txt", repository: testRepository)))
        XCTAssert(secondTree.treeEntries[3].equals(TreeEntry(mode: .blob, hash: "6b3b273987213e28230958801876aff0876376e7", name: "second.txt", repository: testRepository)))
    }

}

private extension TreeEntry {

    func equals(_ treeEntry: TreeEntry) -> Bool {
        return mode == treeEntry.mode && hash == treeEntry.hash && name == treeEntry.name
    }
    
}


