//
//  Index.swift
//  Git
//
//  Created by Jake Heiser on 8/22/16.
//
//

import Foundation
import FileKit

class Index {
    
    let version: Int
    
    enum Error: Swift.Error {
        case readError
        case parseError
    }
    
    let repository: Repository
    
    init(repository: Repository) throws {
        let indexPath = repository.subpath(with: "index")
        guard let fileReader = FileReader(path: indexPath) else {
            throw Error.readError
        }
        guard fileReader.read(next: 4) == "DIRC" else {
            throw Error.parseError
        }
        
        guard let version = Int(fileReader.readHex(length: 4), radix: 16) else {
            throw Error.parseError
        }
        self.version = version
        
        guard let count = Int(fileReader.readHex(length: 4), radix: 16) else {
            throw Error.parseError
        }
        print(version, count)
        
//        for i in 0 ..< count {
//            
//        }
        
        self.repository = repository
    }
    
}

extension Repository {
    
    var index: Index? {
        return try? Index(repository: self)
    }
    
}
