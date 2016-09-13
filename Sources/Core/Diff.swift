//
//  Diff.swift
//  Git
//
//  Created by Jake Heiser on 9/12/16.
//
//

import FileKit

public class Diff {
    
    public let fileDiffs: [FileDiff]
    
    enum Error: Swift.Error {
        case unreadableIndex
        case missingFile
    }
    
    public static func diffWorkingDirectoryAndIndex(in repository: Repository) throws -> Diff {
        guard let index = repository.index else {
            throw Error.unreadableIndex
        }
        
        var fileDiffs: [FileDiff] = []
        for (file, status) in index.unstagedChanges().deltaFiles {
            if status == .untracked { // Don't diff untracked files
                continue
            }
            
            guard let indexEntry = index[file], let blob = repository.objectStore[indexEntry.hash] as? Blob else {
                throw Error.missingFile
            }
            
            let tmpComparison = Path.UserTemporary + indexEntry.hash
            try blob.data.write(to: tmpComparison)
            fileDiffs.append(FileDiff(original: tmpComparison, new: (repository.path + file), fileName: file))
        }
        
        return Diff(fileDiffs: fileDiffs)
    }
    
    public init(fileDiffs: [FileDiff]) {
        self.fileDiffs = fileDiffs
    }
    
    public func generateWhole() -> String {
        var text = ""
        for fileDiff in fileDiffs {
            text += fileDiff.generate()?.joined(separator: "\n") ?? ""
        }
        return text
    }
    
}
