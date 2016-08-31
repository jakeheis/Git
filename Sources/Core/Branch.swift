//
//  Branch.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

public class Branch: Reference {
    
    static let refPrefix = "refs/heads"

}

extension Repository {
    
    public var branches: [Branch] {
        var branches: [Branch] = []
        
        let branchesDirectory = subpath(with: Branch.refPrefix)
        branches += branchesDirectory.flatMap { Branch(path: $0, repository: self) }
        
        branches += Reference.packedRefs(in: self).flatMap { $0 as? Branch }
        
        return branches
    }
    
}
