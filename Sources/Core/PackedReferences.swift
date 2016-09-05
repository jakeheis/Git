//
//  PackedReferences.swift
//  Git
//
//  Created by Jake Heiser on 9/5/16.
//
//

import Foundation

public class PackedReferences {
    
    public let tags: [Tag]
    public let branches: [Branch]
    
    init?(repository: Repository) {
        guard let packedRefsText = try? String.readFromPath(repository.subpath(with: "packed-refs")) else {
            return nil
        }
        
        let lines = packedRefsText.components(separatedBy: "\n")
        
        var tags: [Tag] = []
        var branches: [Branch] = []
        
        for line in lines where !line.hasPrefix("#") { // No comments
            let words = line.components(separatedBy: " ")
            if let ref = words.last, let hash = words.first {
                if ref.hasPrefix(Tag.directory) {
                    tags.append(Tag(ref: ref, hash: hash, repository: repository))
                } else if ref.hasPrefix(Branch.directory) {
                    branches.append(Branch(ref: ref, hash: hash, repository: repository))
                }
            }
        }
        
        self.tags = tags
        self.branches = branches
    }
    
}

extension Repository {
    
    var packedReferences: PackedReferences? {
        return PackedReferences(repository: self)
    }
    
}
