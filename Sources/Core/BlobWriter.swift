//
//  BlobWriter.swift
//  Git
//
//  Created by Jake Heiser on 9/5/16.
//
//

import Foundation
import FileKit

public class BlobWriter {
    
    enum Error: Swift.Error {
        case readError
    }
    
    let file: Path
    let repository: Repository
    
    public init(file: Path, repository: Repository) {
        self.file = file
        self.repository = repository
    }
    
    public func write() throws -> Blob {
        let blob = try createWithoutWrite()
        try blob.write()
        return blob
    }
    
    public func createWithoutWrite() throws -> Blob {
        let contentData: Data
        
        let isSymlink = (try? FileManager.default.attributesOfItem(atPath: file.rawValue)[FileAttributeKey.type]) as? String == FileAttributeType.typeSymbolicLink.rawValue // Don't use built in function on Path - it's slower
        if isSymlink {
            guard let data = (try? FileManager.default.destinationOfSymbolicLink(atPath: file.rawValue))?.data(using: .ascii) else {
                fatalError("Broken symbolic link: \(file)")
            }
            contentData = data
        } else {
            guard let data = try? NSData.readFromPath(file) as Data else {
                throw Error.readError
            }
            contentData = data
        }
        
        var data = Blob.header(for: contentData, type: .blob)
        data.append(contentData)
        
        let hash = DataReader(data: data.sha1).readHex(bytes: 20)
        
        let blob = Blob(hash: hash, data: contentData, repository: repository)
        
        return blob
    }
    
}
