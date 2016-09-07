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

class IndexWriterTests: XCTestCase {

    func testBasicWrite() {
        guard let basicIndex = basicRepository.index,
            let data = try? IndexWriter(index: basicIndex).generateData() else {
                XCTFail()
                return
        }
        XCTAssert(try! Data.read(from: basicRepository.subpath(with: "index")) == data)
    }
    
    func testAddedWrite() {
        guard let index = basicRepository.index else {
            XCTFail()
            return
        }
        
        let newFile = "test.txt"
        let newFilePath = basicRepository.path + newFile
        try! "test".writeToPath(newFilePath)
        defer { clearBasicRepository() }
        
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
        
        executeGitCommand(in: basicRepository, with: ["add", newFile])
        
        XCTAssert(try! Data.read(from: basicRepository.subpath(with: "index")) == data)
    }

    func testModifiedWrite() {
        guard let index = basicRepository.index else {
            XCTFail()
            return
        }
        
        let modifiedFile = "file.txt"
        try! "overwritten".writeToPath(basicRepository.path + modifiedFile)
        defer { clearBasicRepository() }
        
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
        
        executeGitCommand(in: basicRepository, with: ["add", modifiedFile])
        
        XCTAssert(try! Data.read(from: basicRepository.subpath(with: "index")) == data)
    }
    
    func testRemovedWrite() {
        guard let index = basicRepository.index else {
            XCTFail()
            return
        }
        
        let deletedFile = "file.txt"
        try! (basicRepository.path + deletedFile).deleteFile()
        defer { clearBasicRepository() }
        
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
        
        executeGitCommand(in: basicRepository, with: ["add", deletedFile])
        
        XCTAssert(try! Data.read(from: basicRepository.subpath(with: "index")) == data)
    }
    
    
    
}
