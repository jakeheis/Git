//
//  ObjectStoreTests.swift
//  Git
//
//  Created by Jake Heiser on 8/31/16.
//
//

import XCTest
@testable import Core

class ObjectStoreTests: XCTestCase {

    func testFileObjectRetrieval() {
        let blob = basicRepository.objectStore.objectFromFile(hash: "4260dd4b89d8b3f9a231538664bd3d346fdd2ead") as! Blob
        XCTAssert(blob.hash == "4260dd4b89d8b3f9a231538664bd3d346fdd2ead")
        XCTAssert(String(data: blob.data, encoding: .ascii) == "File\nmodification\nanother mod\n")
    }
    
    func testPackfileObjectRetrieval() {
        let blob = packedRepository.objectStore.objectFromPackfile(hash: "4260dd4b89d8b3f9a231538664bd3d346fdd2ead") as! Blob
        XCTAssert(blob.hash == "4260dd4b89d8b3f9a231538664bd3d346fdd2ead")
        XCTAssert(String(data: blob.data, encoding: .ascii) == "File\nmodification\nanother mod\n")
    }
    
    func testReadAllFromFiles() {
        let all = basicRepository.objectStore.allObjects()
        XCTAssert(all.count == 23)
    }
    
    func testReadAllFromPackfile() {
        let all = packedRepository.objectStore.allObjects()
        XCTAssert(all.count == 23)
    }

}
