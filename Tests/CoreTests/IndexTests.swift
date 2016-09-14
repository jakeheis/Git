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

class IndexTests: GitTestCase {
    
    func testParse() {
        let repository = TestRepositories.repository(.basic, at: "29287d7a61db5b55e66f707a01b7fb4b11efcb40")
        
        guard let index = repository.index else {
            XCTFail()
            return
        }
        XCTAssert(index.entries[0].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 29, hash: "3a79a681b63d71c6c7c22bdefcb3e4e8d3988a5b", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "Subdirectory/subfile.txt"))
        XCTAssert(index.entries[1].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 18, hash: "aa3350c980eda0524c9ec6db48a613425f756b68", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "file.txt"))
        XCTAssert(index.entries[2].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 27, hash: "e20f5916c1cb235a7f26cd91e09a40e277d38306", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "other_file.txt"))
        XCTAssert(index.entries[3].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 32, hash: "6b3b273987213e28230958801876aff0876376e7", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "second.txt"))
    }
    
    func testIndexTreeDelta() {
        let repository = TestRepositories.repository(.basic, at: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        
        let treePath = repository.subpath(with: "objects/1f/9bcfa09c52c0e5c7df0aa6953ffff8dffdf3c5")
        guard let index = repository.index,
            let tree = try? Tree.read(from: treePath, in: repository) else {
                XCTFail()
                return
        }
        
        let delta = IndexDelta(index: index, tree: tree)
        
        guard delta.deltaFiles.count == 3 else {
            XCTFail()
            return
        }
        
        XCTAssert(delta.deltaFiles[0] == ("file.txt", .modified))
        XCTAssert(delta.deltaFiles[1] == ("second.txt", .deleted))
        XCTAssert(delta.deltaFiles[2] == ("third.txt", .added))
    }
    
    func testIndexWorkingDirectoryDelta() {
        let repository = TestRepositories.repository(.basic, at: "db69d97956555ed0ebf9e4a7ff4fedd8c08ba717")
        
        let hiFile = repository.path + "hi.txt"
        try! "hi".writeToPath(hiFile)
        try! (repository.path + "third.txt").deleteFile()
        defer { try! hiFile.deleteFile() }
        
        Thread.sleep(forTimeInterval: 1) // Make sure stat values for initial creation and modification are different
        try! "overwritten".writeToPath(repository.path + "file.txt")
        
        guard let index = repository.index else {
            XCTFail()
            return
        }
        let delta = IndexDelta(index: index, repository: repository)
        
        guard delta.deltaFiles.count == 3 else {
            XCTFail()
            return
        }
        
        XCTAssert(delta.deltaFiles[0] == ("file.txt", .modified))
        XCTAssert(delta.deltaFiles[1] == ("hi.txt", .untracked))
        XCTAssert(delta.deltaFiles[2] == ("third.txt", .deleted))
    }
    
    func testAddEntry() {
        let repository = TestRepositories.repository(.emptyObjects)
        guard let index = repository.index else {
            XCTFail()
            return
        }
        
        let newFile1 = "sub/test.txt"
        let newFilePath = repository.path + newFile1
        try! "test".writeToPath(newFilePath)
        
        let newFile2 = ".a"
        let newFilePath2 = repository.path + newFile2
        try! "test".writeToPath(newFilePath2)
        
        do {
            try index.add(file: newFile1, write: false)
            try index.add(file: newFile2, write: false)
        } catch {
            XCTFail()
            return
        }
        
        XCTAssert(index.entries.count == 9)
        
        // Check that entry was correctly inserted
        XCTAssert(index.entries[0].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 4, hash: "30d74d258442c7c65512eafab474568dd706c430", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: ".a"))
        XCTAssert(index.entries[1].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 10, hash: "e43b0f988953ae3a84b00331d0ccf5f7d51cb3cf", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: ".gitignore"))
        XCTAssert(index.entries[6].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 8, hash: "d8fc28d60e02f9dbe0aeb88d130aa73d34a5ef37", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "sub/sub.txt"))
        XCTAssert(index.entries[7].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 4, hash: "30d74d258442c7c65512eafab474568dd706c430", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "sub/test.txt"))
        XCTAssert(index.entries[8].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 12, hash: "861dc4f462a6878624c8a14e90e9e496f153133f", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "sub/within.txt"))
        XCTAssert(index["sub/test.txt"]!.equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 4, hash: "30d74d258442c7c65512eafab474568dd706c430", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "sub/test.txt"))
        
        // Check that tree extensions were correctly invalidated
        guard let rootTreeExtension = index.rootTreeExtension else {
            XCTFail()
            return
        }
        XCTAssert(rootTreeExtension.path == "")
        XCTAssert(rootTreeExtension.hash == nil)
        XCTAssert(rootTreeExtension.entryCount == -1)
        XCTAssert(rootTreeExtension.subtrees[0].path == "sub")
        XCTAssert(rootTreeExtension.subtrees[0].hash == nil)
        XCTAssert(rootTreeExtension.subtrees[0].entryCount == -1)
        XCTAssert(rootTreeExtension.subtrees[1].path == "links")
        XCTAssert(rootTreeExtension.subtrees[1].hash == "516e5976d80d068a62f7e03e1af588687775a28d")
        XCTAssert(rootTreeExtension.subtrees[1].entryCount == 2)
    }
    
    func testUpdateEntry() {
        let repository = TestRepositories.repository(.emptyObjects)
        guard let index = repository.index else {
            XCTFail()
            return
        }
        
        let updateFile = "sub/sub.txt"
        let updateFilePath = repository.path + updateFile
        try! "test".writeToPath(updateFilePath)
        
        XCTAssert(index.entries[5].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 8, hash: "d8fc28d60e02f9dbe0aeb88d130aa73d34a5ef37", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "sub/sub.txt"))
        
        do {
            try index.update(file: updateFile, write: false)
        } catch {
            XCTFail()
            return
        }
        
        XCTAssert(index.entries.count == 7)
        
        // Check that entry was correctly inserted
        XCTAssert(index.entries[0].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 10, hash: "e43b0f988953ae3a84b00331d0ccf5f7d51cb3cf", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: ".gitignore"))
        XCTAssert(index.entries[4].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 7, hash: "e019be006cf33489e2d0177a3837a2384eddebc5", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "second.txt"))
        XCTAssert(index.entries[5].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 4, hash: "30d74d258442c7c65512eafab474568dd706c430", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "sub/sub.txt"))
        XCTAssert(index.entries[6].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 12, hash: "861dc4f462a6878624c8a14e90e9e496f153133f", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "sub/within.txt"))
        XCTAssert(index["sub/sub.txt"]!.equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 4, hash: "30d74d258442c7c65512eafab474568dd706c430", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "sub/sub.txt"))
        
        // Check that tree extensions were correctly invalidated
        guard let rootTreeExtension = index.rootTreeExtension else {
            XCTFail()
            return
        }
        XCTAssert(rootTreeExtension.path == "")
        XCTAssert(rootTreeExtension.hash == nil)
        XCTAssert(rootTreeExtension.entryCount == -1)
        XCTAssert(rootTreeExtension.subtrees[0].path == "sub")
        XCTAssert(rootTreeExtension.subtrees[0].hash == nil)
        XCTAssert(rootTreeExtension.subtrees[0].entryCount == -1)
        XCTAssert(rootTreeExtension.subtrees[1].path == "links")
        XCTAssert(rootTreeExtension.subtrees[1].hash == "516e5976d80d068a62f7e03e1af588687775a28d")
        XCTAssert(rootTreeExtension.subtrees[1].entryCount == 2)
    }

    func testRemoveEntry() {
        let repository = TestRepositories.repository(.emptyObjects)
        guard let index = repository.index else {
            XCTFail()
            return
        }
        
        let removeFile = "sub/sub.txt"
        
        XCTAssert(index.entries[5].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 8, hash: "d8fc28d60e02f9dbe0aeb88d130aa73d34a5ef37", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "sub/sub.txt"))
        
        do {
            try index.remove(file: removeFile, write: false)
        } catch {
            XCTFail()
            return
        }
        
        XCTAssert(index.entries.count == 6)
        
        // Check that entry was correctly inserted
        XCTAssert(index.entries[0].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 10, hash: "e43b0f988953ae3a84b00331d0ccf5f7d51cb3cf", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: ".gitignore"))
        XCTAssert(index.entries[4].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 7, hash: "e019be006cf33489e2d0177a3837a2384eddebc5", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "second.txt"))
        XCTAssert(index.entries[5].equals(dev: 16777220, mode: .blob, uid: 501, gid: 20, fileSize: 12, hash: "861dc4f462a6878624c8a14e90e9e496f153133f", assumeValid: false, extended: false, firstStage: false, secondStage: false, name: "sub/within.txt"))
        XCTAssert(index["sub/sub.txt"] == nil)
        
        // Check that tree extensions were correctly invalidated
        guard let rootTreeExtension = index.rootTreeExtension else {
            XCTFail()
            return
        }
        XCTAssert(rootTreeExtension.path == "")
        XCTAssert(rootTreeExtension.hash == nil)
        XCTAssert(rootTreeExtension.entryCount == -1)
        XCTAssert(rootTreeExtension.subtrees[0].path == "sub")
        XCTAssert(rootTreeExtension.subtrees[0].hash == nil)
        XCTAssert(rootTreeExtension.subtrees[0].entryCount == -1)
        XCTAssert(rootTreeExtension.subtrees[1].path == "links")
        XCTAssert(rootTreeExtension.subtrees[1].hash == "516e5976d80d068a62f7e03e1af588687775a28d")
        XCTAssert(rootTreeExtension.subtrees[1].entryCount == 2)
    }
    
    func testModifyWithDirectory() {
        let repository = TestRepositories.repository(.basic)
        guard let index = repository.index else {
            XCTFail()
            return
        }
        
        let directory = repository.path + "Dir"
        do {
            try directory.createDirectory()
            try (directory + "hey.txt").createFile()
            try (directory + "hi.txt").createFile()
            try index.modify(with: directory.fileName, write: false)
        } catch {
            XCTFail()
        }
        
        guard let delta = index.stagedChanges() else {
            XCTFail()
            return
        }
        XCTAssert(delta.deltaFiles[0] == ("Dir/hey.txt", .added))
        XCTAssert(delta.deltaFiles[1] == ("Dir/hi.txt", .added))
    }
    
    func testModifyAll() {
        let repository = TestRepositories.repository(.basic)
        guard let index = repository.index else {
            XCTFail()
            return
        }
        
        do {
            try "TEXT".write(to: (repository.path + "a.txt"))
            try "TEXT".write(to: (repository.path + "file.txt"))
            try (repository.path + "third.txt").deleteFile()
            
            try index.modify(with: ".", write: false)
        } catch {
            XCTFail()
        }
        
        guard let delta = index.stagedChanges() else {
            XCTFail()
            return
        }
        XCTAssert(delta.deltaFiles[0] == ("file.txt", .modified))
        XCTAssert(delta.deltaFiles[1] == ("third.txt", .deleted))
        XCTAssert(delta.deltaFiles[2] == ("a.txt", .added))
    }
    
    func testPartialReset() {
        let repository = TestRepositories.repository(.basic)
        guard let index = repository.index else {
            XCTFail()
            return
        }
        
        do {
            try "TEXT".write(to: (repository.path + "a.txt"))
            try "TEXT".write(to: (repository.path + "file.txt"))
            try (repository.path + "third.txt").deleteFile()
            
            try index.modify(with: ".", write: false)
        } catch {
            XCTFail()
        }
        
        guard let stagedDelta = index.stagedChanges() else {
            XCTFail()
            return
        }
        XCTAssert(stagedDelta.deltaFiles[0] == ("file.txt", .modified))
        XCTAssert(stagedDelta.deltaFiles[1] == ("third.txt", .deleted))
        XCTAssert(stagedDelta.deltaFiles[2] == ("a.txt", .added))
        XCTAssert(index.unstagedChanges().deltaFiles.count == 0)
        
        do {
            try index.reset(files: ["file.txt", "third.txt"])
        } catch {
            XCTFail()
        }
        
        XCTAssert(index.isTracking("a.txt"))
        
        let unstagedDelta = index.unstagedChanges()
        XCTAssert(unstagedDelta.deltaFiles[0] == ("file.txt", .modified))
        XCTAssert(unstagedDelta.deltaFiles[1] == ("third.txt", .deleted))
        
        guard let afterStagedDelta = index.stagedChanges() else {
            XCTFail()
            return
        }
        XCTAssert(afterStagedDelta.deltaFiles[0] == ("a.txt", .added))
    }
    
    func testFullReset () {
        let repository = TestRepositories.repository(.basic)
        guard let index = repository.index else {
            XCTFail()
            return
        }
        
        do {
            try "TEXT".write(to: (repository.path + "a.txt"))
            try "TEXT".write(to: (repository.path + "file.txt"))
            try (repository.path + "third.txt").deleteFile()
            
            try index.modify(with: ".", write: false)
        } catch {
            XCTFail()
        }
        
        guard let stagedDelta = index.stagedChanges() else {
            XCTFail()
            return
        }
        XCTAssert(stagedDelta.deltaFiles[0] == ("file.txt", .modified))
        XCTAssert(stagedDelta.deltaFiles[1] == ("third.txt", .deleted))
        XCTAssert(stagedDelta.deltaFiles[2] == ("a.txt", .added))
        XCTAssert(index.unstagedChanges().deltaFiles.count == 0)
        
        do {
            try index.reset(file: ".")
        } catch {
            XCTFail()
        }
        
        XCTAssert(!index.isTracking("a.txt"))
        XCTAssert(index["file.txt"]?.stat.mSeconds == 0) // Ensure fields are reset
        XCTAssert(index["third.txt"]?.stat.mSeconds == 0) // Ensure fields are reset
        
        let unstagedDelta = index.unstagedChanges()
        XCTAssert(unstagedDelta.deltaFiles[0] == ("a.txt", .untracked))
        XCTAssert(unstagedDelta.deltaFiles[1] == ("file.txt", .modified))
        XCTAssert(unstagedDelta.deltaFiles[2] == ("third.txt", .deleted))
        
        XCTAssert(index.stagedChanges()?.deltaFiles.count == 0)
    }
    
}

private extension IndexEntry {
    
    // Don't check ino or dates because they keep changing every time
    func equals(dev: Int, mode: FileMode, uid: Int, gid: Int, fileSize: Int, hash: String, assumeValid: Bool, extended: Bool, firstStage: Bool, secondStage: Bool, name: String) -> Bool {
        return
                self.stat.dev == dev &&
                self.stat.mode == mode &&
                self.stat.uid == uid &&
                self.stat.gid == gid &&
                self.stat.fileSize == fileSize &&
                self.hash == hash &&
                self.assumeValid == assumeValid &&
                self.extended == extended &&
                self.firstStage == firstStage &&
                self.secondStage == secondStage &&
                self.name == name
        
    }
    
}
