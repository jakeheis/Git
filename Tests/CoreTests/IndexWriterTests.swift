//
//  IndexWriterTests.swift
//  Git
//
//  Created by Jake Heiser on 9/6/16.
//
//

import XCTest
@testable import Core
import FileKit

class IndexWriterTests: GitTestCase {

    func testBasicWrite() {
        let repository = TestRepositories.repository(.basic)
        guard let basicIndex = repository.index,
            let data = try? IndexWriter(index: basicIndex).generateData() else {
                XCTFail()
                return
        }
        XCTAssert(try! Data.read(from: repository.subpath(with: "index")) == data)
    }
    
    func testAddedWrite() {
        let repository = TestRepositories.repository(.basic)
        guard let index = repository.index else {
            XCTFail()
            return
        }
        
        let newFile = "test.txt"
        let newFilePath = repository.path + newFile
        try! "test".writeToPath(newFilePath)
        
        do {
            try index.add(file: newFile, write: false)
        } catch {
            XCTFail()
            return
        }
        
        guard let data = try? IndexWriter(index: index).generateData() else {
            XCTFail()
            return
        }
        
        executeGitCommand(in: repository, with: ["add", newFile])
        
        XCTAssert(try! Data.read(from: repository.subpath(with: "index")) == data)
    }

    func testModifiedWrite() {
        let repository = TestRepositories.repository(.basic)
        guard let index = repository.index else {
            XCTFail()
            return
        }
        
        let modifiedFile = "file.txt"
        try! "overwritten".writeToPath(repository.path + modifiedFile)
        
        do {
            try index.update(file: modifiedFile, write: false)
        } catch {
            XCTFail()
            return
        }
        
        guard let data = try? IndexWriter(index: index).generateData() else {
            XCTFail()
            return
        }
        
        executeGitCommand(in: repository, with: ["add", modifiedFile])
        
        XCTAssert(try! Data.read(from: repository.subpath(with: "index")) == data)
    }
    
    func testRemovedWrite() {
        let repository = TestRepositories.repository(.basic)
        guard let index = repository.index else {
            XCTFail()
            return
        }
        
        let deletedFile = "file.txt"
        try! (repository.path + deletedFile).deleteFile()
        
        do {
            try index.remove(file: deletedFile, write: false)
        } catch {
            XCTFail()
            return
        }
        
        guard let data = try? IndexWriter(index: index).generateData() else {
            XCTFail()
            return
        }
        
        executeGitCommand(in: repository, with: ["add", deletedFile])
        
        XCTAssert(try! Data.read(from: repository.subpath(with: "index")) == data)
    }
    
    
    
}
