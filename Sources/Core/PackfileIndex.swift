//
//  PackfileIndex.swift
//  Git
//
//  Created by Jake Heiser on 8/24/16.
//
//

import Foundation
import FileKit

public class PackfileIndex {
    
    static let packDirectory = ".git/objects/pack/"
    
    convenience init?(name: String, repository: Repository) {
        let path = repository.subpath(with: PackfileIndex.packDirectory + name)
        self.init(path: path, repository: repository)
    }
    
    init?(path: Path, repository: Repository) {
        guard path.pathExtension == "idx" else {
            return nil
        }
        guard let dataReader = DataReader(path: path) else {
            return nil
        }
        
        let header = dataReader.readData(bytes: 4)
        guard Array(header) == [255, 116, 79, 99],
            let version = dataReader.readInt(bytes: 4) else {
            return nil
        }
        
        print(version)
    }
    
}

extension Repository {
    
    public var packfileIndices: [PackfileIndex] {
        let packDirectory = Path(PackfileIndex.packDirectory)
        return packDirectory.flatMap { (packIndexPath) in
            return PackfileIndex(path: packIndexPath, repository: self)
        }
    }
    
}
