//
//  IndexTests.swift
//  Git
//
//  Created by Jake Heiser on 8/30/16.
//
//

import XCTest
@testable import Core
import FileKit

class IndexTests: XCTestCase {
    
    func testParse() {
        basicRepository.checkout("29287d7a61db5b55e66f707a01b7fb4b11efcb40") {
            guard let index = basicRepository.index else {
                XCTFail()
                return
            }
            XCTAssert(index.entries[0].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 29, hash: "3a79a681b63d71c6c7c22bdefcb3e4e8d3988a5b", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "Subdirectory/subfile.txt"))
            XCTAssert(index.entries[1].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 18, hash: "aa3350c980eda0524c9ec6db48a613425f756b68", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "file.txt"))
            XCTAssert(index.entries[2].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 27, hash: "e20f5916c1cb235a7f26cd91e09a40e277d38306", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "other_file.txt"))
            XCTAssert(index.entries[3].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 32, hash: "6b3b273987213e28230958801876aff0876376e7", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "second.txt"))
        }
    }
    
    func testIndexTreeDelta() {
        basicRepository.checkout("db69d97956555ed0ebf9e4a7ff4fedd8c08ba717") {
            let treePath = basicRepository.subpath(with: "objects/1f/9bcfa09c52c0e5c7df0aa6953ffff8dffdf3c5")
            guard let index = basicRepository.index,
                let tree = try? Tree.read(from: treePath, in: basicRepository) else {
                XCTFail()
                return
            }
            
            let delta = IndexDelta(index: index, tree: tree)
            
            XCTAssert(delta.deltaFiles[0] == ("file.txt", .modified))
            XCTAssert(delta.deltaFiles[1] == ("second.txt", .deleted))
            XCTAssert(delta.deltaFiles[2] == ("third.txt", .added))
        }
    }
    
    func testIndexWorkingDirectoryDelta() {
        basicRepository.checkout("db69d97956555ed0ebf9e4a7ff4fedd8c08ba717") {
            let hiFile = basicRepository.path + "hi.txt"
            try! "hi".writeToPath(hiFile)
            try! (basicRepository.path + "third.txt").deleteFile()
            try! "overwritten".writeToPath(basicRepository.path + "file.txt")
            
            guard let index = basicRepository.index else {
                XCTFail()
                return
            }
            let delta = IndexDelta(index: index, repository: basicRepository)
            
            XCTAssert(delta.deltaFiles[0] == ("file.txt", .modified))
            XCTAssert(delta.deltaFiles[1] == ("hi.txt", .untracked))
            XCTAssert(delta.deltaFiles[2] == ("third.txt", .deleted))
                        
            try! hiFile.deleteFile()
        }
    }

}

private extension IndexEntry {
    
    // Don't check ino or dates because they keep changing every time
    func equals(dev: Int, mode: FileMode, uid: Int, gid: Int, fileSize: Int, hash: String, assumeValid: Bool, extended: Bool, firstStage: Bool, secondStage: Bool, name: String) -> Bool {
        return
                self.dev == dev &&
                self.ino == ino &&
                self.mode == mode &&
                self.uid == uid &&
                self.gid == gid &&
                self.fileSize == fileSize &&
                self.hash == hash &&
                self.assumeValid == assumeValid &&
                self.extended == extended &&
                self.firstStage == firstStage &&
                self.secondStage == secondStage &&
                self.name == name
        
    }
    
}
