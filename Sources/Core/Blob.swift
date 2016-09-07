//
//  Blob.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

import Foundation
import FileKit

final public class Blob: Object {
    
    public let hash: String
    public let type: ObjectType = .blob
    public let repository: Repository
    
    public let data: Data
    
    public init(hash: String, data: Data, repository: Repository) {
        self.data = data
        self.hash = hash
        self.repository = repository
    }
    
    public func cat() -> String {
        let contents = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? "(Could not represent blob data as string)"
        return contents
    }
    
    public func generateContentData() -> Data {
        return data
    }
    
}
