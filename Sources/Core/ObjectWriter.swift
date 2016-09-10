//
//  ObjectWriter.swift
//  Git
//
//  Created by Jake Heiser on 9/9/16.
//
//

import Foundation
import FileKit

protocol ObjectWriter {
    
    associatedtype Object: Core.Object
    
    var repository: Repository { get }
    
    func generateContentData() throws -> Data
    
}

extension ObjectWriter {
    
    func generateHeader(for contentData: Data, type: ObjectType) -> Data {
        let header = "\(type.rawValue) \(contentData.count)\0"
        guard let headerData = header.data(using: .ascii) else {
            fatalError("Something went very wrong")
        }
        return headerData
    }
    
    func generateData() throws -> Data {
        let content = try generateContentData()
        var data = generateHeader(for: content, type: ObjectType(objectClass: Object.self))
        data.append(content)
        return data
    }
    
    public func generateHash(for data: Data? = nil) throws -> String {
        let dataToSha: Data
        if let data = data {
            dataToSha = data
        } else {
            dataToSha = try generateData()
        }
        return DataReader(data: dataToSha.sha1).readHex(bytes: 20)
    }
    
    @discardableResult
    public func write() throws -> String {
        let data = try generateData()
        let hash = try generateHash(for: data)
        
        let breakIndex = hash.index(hash.startIndex, offsetBy: 2)
        let firstTwo = hash.substring(to: breakIndex)
        let hashEnd = hash.substring(from: breakIndex)
        
        let parentDirectory = repository.subpath(with: "\(ObjectStore.directory)/\(firstTwo)")
        let file = parentDirectory + hashEnd
        
        guard let compressed = data.compressed() else {
            throw WriteError.compressionError
        }
        
        do {
            if !parentDirectory.isAny {
                try parentDirectory.createDirectory()
            }
            try compressed.write(to: file)
        } catch {
            throw WriteError.writeError
        }
        
        return hash
    }
    
}

enum WriteError: Swift.Error {
    case compressionError
    case writeError
}
