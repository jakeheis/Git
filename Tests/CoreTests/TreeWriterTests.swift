//
//  TreeWriterTests.swift
//  Git
//
//  Created by Jake Heiser on 9/5/16.
//
//

import XCTest
@testable import Core

class TreeWriterTests: XCTestCase {

    func testWrite() {
        let writer = TreeWriter(index: writeRepository.index!)
        
        let tree: Tree
        do {
            tree = try writer.write(checkMissing: false)
        } catch {
            XCTFail()
            return
        }
        
        XCTAssert(tree.hash == "b0bd9fc1df38efc9e270e1a515c614e341eac8fc")
        
        XCTAssert(tree.treeEntries[0].equals(mode: .blob, hash: "e43b0f988953ae3a84b00331d0ccf5f7d51cb3cf", name: ".gitignore"))

        XCTAssert(tree.treeEntries[1].equals(mode: .blob, hash: "51f466f2e446ade0b0b2e5778ce3e0fa95e380e8", name: "file.txt"))
        
        XCTAssert(tree.treeEntries[2].equals(mode: .directory, hash: "516e5976d80d068a62f7e03e1af588687775a28d", name: "links"))
        guard let firstSubtree = tree.treeEntries[2].object as? Tree else {
            XCTFail()
            return
        }
        XCTAssert(firstSubtree.hash == "516e5976d80d068a62f7e03e1af588687775a28d")
        XCTAssert(firstSubtree.treeEntries[0].equals(mode: .link, hash: "4c330738cc959751fb6760a91a50d9e58cfe5cb9", name: "f1"))
        XCTAssert(firstSubtree.treeEntries[1].equals(mode: .link, hash: "296e767a46edd9cdcaa2c7b12df27606abd5a01b", name: "sf"))
        
        XCTAssert(tree.treeEntries[3].equals(mode: .blob, hash: "e019be006cf33489e2d0177a3837a2384eddebc5", name: "second.txt"))
        
        XCTAssert(tree.treeEntries[4].equals(mode: .directory, hash: "ff8968529794cb928822ca2c23b4eba1d67fe3f3", name: "sub"))
        guard let secondSubtree = tree.treeEntries[4].object as? Tree else {
            XCTFail()
            return
        }
        XCTAssert(secondSubtree.hash == "ff8968529794cb928822ca2c23b4eba1d67fe3f3")
        XCTAssert(secondSubtree.treeEntries[0].equals(mode: .blob, hash: "d8fc28d60e02f9dbe0aeb88d130aa73d34a5ef37", name: "sub.txt"))
        XCTAssert(secondSubtree.treeEntries[1].equals(mode: .blob, hash: "861dc4f462a6878624c8a14e90e9e496f153133f", name: "within.txt"))
        
        clearWriteRepository()
    }
    
    

}
