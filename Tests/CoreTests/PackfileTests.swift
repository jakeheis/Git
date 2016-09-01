//
//  PackfileTests.swift
//  Git
//
//  Created by Jake Heiser on 8/31/16.
//
//

import XCTest
@testable import Core

class PackfileTests: XCTestCase {

    let packfile = Packfile(name: "pack-a74bd7bba3ae75e0093b5b120b103cbab5340e59.pack", repository: packedRepository)!
    
    func testReadChunk() {
        let commitChunk = packfile.readChunk(at: 267, hash: "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(commitChunk?.objectType == .commit)
        XCTAssert(commitChunk?.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(commitChunk?.offset == 267)
        
        let commit = commitChunk!.object(in: packedRepository) as! Commit
        XCTAssert(commit.hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(commit.treeHash == "1f1ace28d590693be994c10b3c2895cb62da6229")
        XCTAssert(commit.message == "Subdirectory")
        
        let treeChunk = packfile.readChunk(at: 1104, hash: "1f1ace28d590693be994c10b3c2895cb62da6229")
        XCTAssert(treeChunk?.objectType == .tree)
        XCTAssert(treeChunk?.hash == "1f1ace28d590693be994c10b3c2895cb62da6229")
        XCTAssert(treeChunk?.offset == 1104)
        
        let tree = treeChunk!.object(in: packedRepository) as! Tree
        XCTAssert(tree.hash == "1f1ace28d590693be994c10b3c2895cb62da6229")
        XCTAssert(tree.treeEntries[0].equals(mode: .directory, hash: "5e5176fa30d950855ef3a9b9050111328b968971", name: "Subdirectory"))
        XCTAssert(tree.treeEntries[1].equals(mode: .blob, hash: "aa3350c980eda0524c9ec6db48a613425f756b68", name: "file.txt"))
        XCTAssert(tree.treeEntries[2].equals(mode: .blob, hash: "e20f5916c1cb235a7f26cd91e09a40e277d38306", name: "other_file.txt"))
        XCTAssert(tree.treeEntries[3].equals(mode: .blob, hash: "6b3b273987213e28230958801876aff0876376e7", name: "second.txt"))
        
        let blobChunk = packfile.readChunk(at: 1544, hash: "234496b1caf2c7682b8441f9b866a7e2420d9748")
        XCTAssert(blobChunk?.objectType == .blob)
        XCTAssert(blobChunk?.hash == "234496b1caf2c7682b8441f9b866a7e2420d9748")
        XCTAssert(blobChunk?.offset == 1544)
        
        let blob = blobChunk!.object(in: packedRepository) as! Blob
        XCTAssert(blob.hash == "234496b1caf2c7682b8441f9b866a7e2420d9748")
        XCTAssert(String(data: blob.data, encoding: .utf8) == "third\n")
    }
    
    func testDeltifiedChunk() {
        let deltifiedChunk = packfile.readChunk(at: 1300, hash: "11bbaed2e1c68b714e12e35615aedbe3c2a4e760")
        XCTAssert(deltifiedChunk?.objectType == .tree)
        XCTAssert(deltifiedChunk?.hash == "11bbaed2e1c68b714e12e35615aedbe3c2a4e760")
        XCTAssert(deltifiedChunk?.offset == 1300)
        XCTAssert(deltifiedChunk?.deltaInfo?.depth == 1)
        
        let tree = deltifiedChunk!.object(in: packedRepository) as! Tree
        XCTAssert(tree.treeEntries.count == 3)
        XCTAssert(tree.treeEntries[0].equals(mode: .blob, hash: "aa3350c980eda0524c9ec6db48a613425f756b68", name: "file.txt"))
        XCTAssert(tree.treeEntries[1].equals(mode: .blob, hash: "e20f5916c1cb235a7f26cd91e09a40e277d38306", name: "other_file.txt"))
        XCTAssert(tree.treeEntries[2].equals(mode: .blob, hash: "6b3b273987213e28230958801876aff0876376e7", name: "second.txt"))
    }
    
    func testDepthDeltifiedChunk() {
        let deltifiedChunk = packfile.readChunk(at: 1317, hash: "1f9bcfa09c52c0e5c7df0aa6953ffff8dffdf3c5")
        XCTAssert(deltifiedChunk?.objectType == .tree)
        XCTAssert(deltifiedChunk?.hash == "1f9bcfa09c52c0e5c7df0aa6953ffff8dffdf3c5")
        XCTAssert(deltifiedChunk?.offset == 1317)
        XCTAssert(deltifiedChunk?.deltaInfo?.depth == 2)
        
        let tree = deltifiedChunk!.object(in: packedRepository) as! Tree
        XCTAssert(tree.treeEntries.count == 2)
        XCTAssert(tree.treeEntries[0].equals(mode: .blob, hash: "aa3350c980eda0524c9ec6db48a613425f756b68", name: "file.txt"))
        XCTAssert(tree.treeEntries[1].equals(mode: .blob, hash: "6b3b273987213e28230958801876aff0876376e7", name: "second.txt"))
    }
    
    func testReadAll() {
        let chunks = packfile.readAll()
        
        XCTAssert(chunks.count == 23)
        
        XCTAssert(chunks[2].offset == 267)
        XCTAssert(chunks[2].hash == "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        XCTAssert(chunks[2].objectType == .commit)
        
        XCTAssert(chunks[10].offset == 1300)
        XCTAssert(chunks[10].hash == "11bbaed2e1c68b714e12e35615aedbe3c2a4e760")
        XCTAssert(chunks[10].objectType == .tree)
        XCTAssert(chunks[10].packfileSize == 17)
        XCTAssert(chunks[10].deltaInfo?.depth == 1)
        XCTAssert(chunks[10].deltaInfo?.parentHash == "1f1ace28d590693be994c10b3c2895cb62da6229")
        XCTAssert(chunks[10].deltaInfo?.deltaDataLength == 6)
    }
    
    func testCount() {
        XCTAssert(packedRepository.packfiles.count == 1)
    }

}
