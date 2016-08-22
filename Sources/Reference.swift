//
//  Reference.swift
//  Git
//
//  Created by Jake Heiser on 8/21/16.
//
//

import Foundation
import FileKit

class Reference {
    
    let path: Path
    let hash: String
    
    var name: String {
        return path.fileName
    }
    
    init?(path: Path) {
        guard let hash = try? String.readFromPath(path) else {
            return nil
        }
        
        self.path = path
        self.hash = hash.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
}
