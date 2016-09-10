//
//  BlobWriterTests.swift
//  Git
//
//  Created by Jake Heiser on 9/10/16.
//
//

import XCTest
@testable import Core
import FileKit

class BlobWriterTests: XCTestCase {

    func testCreation() {
        let repository = TestRepositories.repository(.emptyObjects)
        
        let path = repository.path + "file.txt"
        guard let hash = try? BlobWriter(from: path, repository: repository).write() else {
            XCTFail()
            return
        }
        XCTAssert(hash == "51f466f2e446ade0b0b2e5778ce3e0fa95e380e8")
        
        let blob = repository.objectStore[hash] as! Blob
        
        XCTAssert(blob.hash == "51f466f2e446ade0b0b2e5778ce3e0fa95e380e8")
        let matchData = try! Data.read(from: path)
        XCTAssert(blob.data == matchData)
    }
    
}
