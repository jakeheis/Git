//
//  Branch.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

final public class Branch: FolderedRefence {
    
    static let directory = "refs/heads"

}

// MARK: -

extension Repository {
    
    public var branches: [Branch] {
        var branches: [Branch] = []
        
        let branchesDirectory = subpath(with: Branch.directory)
        branches += branchesDirectory.flatMap { Branch(path: $0, repository: self) }
        
        if let packedReferences = packedReferences {
            branches += packedReferences.branches
        }
        
        return branches
    }
    
}
