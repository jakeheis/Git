//
//  Branch.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

public class Branch: Reference {

}

extension Repository {
    
    public var branches: [Branch] {
        get {
            let branchRefs = "refs/heads"
            let branchesDirectory = subpath(with: branchRefs)
            return branchesDirectory.flatMap { Branch(ref: branchRefs + "/" + $0.fileName, repository: self) }
        }
    }
    
}
