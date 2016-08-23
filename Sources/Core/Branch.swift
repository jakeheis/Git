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
            let branchesDirectory = subpath(with: "refs/heads")
            return branchesDirectory.flatMap { Branch(path: $0, repository: self) }
        }
    }
    
}
