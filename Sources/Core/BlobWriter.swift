//
//  BlobWriter.swift
//  Git
//
//  Created by Jake Heiser on 9/5/16.
//
//

import Foundation
import FileKit

final public class BlobWriter: ObjectWriter {
    
    enum Error: Swift.Error {
        case readError
    }
    
    let data: Data
    let repository: Repository
    
    public init(from file: Path, repository: Repository) throws {
        let isSymlink = (try? FileManager.default.attributesOfItem(atPath: file.rawValue)[FileAttributeKey.type]) as? String == FileAttributeType.typeSymbolicLink.rawValue // Don't use built in function on Path - it's slower
        if isSymlink {
            guard let data = (try? FileManager.default.destinationOfSymbolicLink(atPath: file.rawValue))?.data(using: .ascii) else {
                fatalError("Broken symbolic link: \(file)")
            }
            self.data = data
        } else {
            guard let data = try? NSData.readFromPath(file) as Data else {
                throw Error.readError
            }
            self.data = data
        }
        
        self.repository = repository
    }
    
    init(object: Blob) {
        self.data = object.data
        self.repository = object.repository
    }
    
    func generateContentData() throws -> Data {
        return data
    }
    
}
