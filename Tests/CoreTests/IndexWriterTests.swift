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
        guard let index = writeRepository.index else {
            XCTFail()
            return
        }
        
        let newFile = "sub/test.txt"
        let newFilePath = writeRepository.path + newFile
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
        
        executeGitCommand(in: writeRepository, with: ["add", newFile])
        
        XCTAssert(try! Data.read(from: writeRepository.subpath(with: "index")) == data)
        
        clearWriteRepository()
    }

//    func testModifiedWrite() {
//        guard let basicIndex = basicRepository.index,
//            let data = try? IndexWriter(index: basicIndex).generateData() else {
//                XCTFail()
//                return
//        }
//        XCTAssert(try! Data.read(from: basicRepository.subpath(with: "index")) == data)
//    }
    
}
