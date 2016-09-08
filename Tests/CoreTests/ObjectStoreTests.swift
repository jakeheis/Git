//
//  ObjectStoreTests.swift
//  Git
//
//  Created by Jake Heiser on 8/31/16.
//
//

import XCTest
@testable import Core
import FileKit

class ObjectStoreTests: GitTestCase {

    func testFileObjectRetrieval() {
        let repository = TestRepositories.repository(.basic)
        
        let blob = repository.objectStore.objectFromFile(hash: "4260dd4b89d8b3f9a231538664bd3d346fdd2ead") as! Blob
        XCTAssert(blob.hash == "4260dd4b89d8b3f9a231538664bd3d346fdd2ead")
        XCTAssert(String(data: blob.data, encoding: .ascii) == "File\nmodification\nanother mod\n")
    }
    
    func testPackfileObjectRetrieval() {
        let repository = TestRepositories.repository(.packed)
        
        let blob = repository.objectStore.objectFromPackfile(hash: "4260dd4b89d8b3f9a231538664bd3d346fdd2ead") as! Blob
        XCTAssert(blob.hash == "4260dd4b89d8b3f9a231538664bd3d346fdd2ead")
        XCTAssert(String(data: blob.data, encoding: .ascii) == "File\nmodification\nanother mod\n")
    }
    
    func testReadAllFromFiles() {
        let repository = TestRepositories.repository(.basic)
        
        let all = repository.objectStore.allObjects()
        XCTAssert(all.count == 24)
    }
    
    func testReadAllFromPackfile() {
        let repository = TestRepositories.repository(.packed)
        
        let all = repository.objectStore.allObjects()
        XCTAssert(all.count == 23)
    }
    
    func testReadShortHash() {
        let repository = TestRepositories.repository(.basic)
        
        guard let blob = repository.objectStore.objectFromFile(hash: "4260dd4") as? Blob else {
            XCTFail()
            return
        }
        XCTAssert(blob.hash == "4260dd4b89d8b3f9a231538664bd3d346fdd2ead")
        XCTAssert(String(data: blob.data, encoding: .ascii) == "File\nmodification\nanother mod\n")
        
        guard let packedBlob = repository.objectStore.objectFromFile(hash: "4260dd4") as? Blob else {
            XCTFail()
            return
        }
        XCTAssert(packedBlob.hash == "4260dd4b89d8b3f9a231538664bd3d346fdd2ead")
        XCTAssert(String(data: packedBlob.data, encoding: .ascii) == "File\nmodification\nanother mod\n")
    }
    
    func testWrite() {
        let readRepository = TestRepositories.repository(.basic)
        let writeRepository = TestRepositories.repository(.emptyObjects)
        
        guard let originalBlob = readRepository.objectStore["4260dd4b89d8b3f9a231538664bd3d346fdd2ead"] as? Blob else {
            XCTFail()
            return
        }
        
        do {
            try writeRepository.objectStore.write(object: originalBlob)
        } catch {
            XCTFail()
            return
        }
        
        guard let sameBlob = writeRepository.objectStore["4260dd4b89d8b3f9a231538664bd3d346fdd2ead"] as? Blob else {
            XCTFail()
            return
        }
        
        XCTAssert(sameBlob.hash == originalBlob.hash)
        XCTAssert(sameBlob.data == originalBlob.data)
    }

}
