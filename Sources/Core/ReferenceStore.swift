//
//  ReferenceStore.swift
//  Git
//
//  Created by Jake Heiser on 10/14/16.
//
//

import Foundation
import FileKit

public class ReferenceStore {
    
    let repository: Repository
    let backings: [ReferenceStoreBacking]
    
    init(repository: Repository) {
        self.repository = repository
        self.backings = [FileReferenceStoreBacking(repository: repository), PackReferenceStoreBacking(repository: repository)]
    }
    
    public subscript(raw: String) -> Reference? {
        return self[Ref(raw)]
    }
    
    public subscript(ref: Ref) -> Reference? {
        for backing in backings {
            if let reference = backing[ref] {
                return reference
            }
        }
        return nil
    }
    
    public func allBranches() -> [Reference] {
        var branches: [Reference] = []
        for backing in backings {
            let new = backing.allBranches()
            for branch in new where !branches.contains(where: { $0.ref == branch.ref }) {
                branches.append(branch)
            }
        }
        return branches
    }
    
    public func allTags() -> [Reference] {
        var tags: [Reference] = []
        for backing in backings {
            let new = backing.allTags()
            for tag in new where !tags.contains(where: { $0.ref == tag.ref }) {
                tags.append(tag)
            }
        }
        return tags
    }
    
}

// MARK: - Backings

protocol ReferenceStoreBacking {
    init(repository: Repository)
    
    subscript(ref: Ref) -> Reference? { get }
    
    func allBranches() -> [Reference]
    func allTags() -> [Reference]
}

final fileprivate class FileReferenceStoreBacking: ReferenceStoreBacking {
    
    let repository: Repository
    
    init(repository: Repository) {
        self.repository = repository
    }
    
    subscript(ref: Ref) -> Reference? {
        let file = repository.subpath(with: ref.path)
        if let reference = read(ref: ref, from: file) {
            return reference
        }
        
        let directory = repository.subpath(with: Ref.prefix)
        if let searched = directory.first(where: { $0.rawValue.hasSuffix(ref.path) }) {
            let components = searched.components
            guard let index = components.index(of: Path(Ref.prefix)) else {
                return nil
            }
            let path = searched[index ..< components.count - 1] + searched.fileName
            return read(ref: Ref(path.rawValue), from: searched)
        }
        return nil
    }
    
    private func read(ref: Ref, from file: Path) -> Reference? {
        guard file.exists,
            let text = (try? String.readFromPath(file))?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return nil
        }
        if text.characters.count == 40 {
            return SimpleReference(ref: ref, hash: text, repository: repository)
        } else if text.hasPrefix(SymbolicReference.prefix) {
            return SymbolicReference(ref: ref, text: text, repository: repository)?.dereferenced
        }
        return nil
    }
    
    func allBranches() -> [Reference] {
        let branchesDirectory = repository.subpath(with: Ref.branches)
        return branchesDirectory.flatMap({ read(ref: Ref(Ref.branches + "/" + $0.fileName), from: $0) })
    }
    
    func allTags() -> [Reference] {
        let tagsDirectory = repository.subpath(with: Ref.tags)
        return tagsDirectory.flatMap({ read(ref: Ref(Ref.tags + "/" + $0.fileName), from: $0) })
    }
    
}

final fileprivate class PackReferenceStoreBacking: ReferenceStoreBacking {
    
    let repository: Repository
    let references: [Ref: Reference]
    
    let branches: [Ref]
    let tags: [Ref]
    
    init(repository: Repository) {
        self.repository = repository
        
        var references: [Ref: Reference] = [:]
        var tags: [Ref] = []
        var branches: [Ref] = []
        
        if let packedRefsText = try? String.readFromPath(repository.subpath(with: "packed-refs")) {
            let lines = packedRefsText.components(separatedBy: "\n")
            
            loop: for line in lines where !line.hasPrefix("#") && !line.isEmpty { // No comments
                let words = line.components(separatedBy: " ")
                if let lastWord = words.last, let hash = words.first {
                    let ref = Ref(lastWord)
                    if ref.isTag {
                        tags.append(ref)
                    } else if ref.isBranch {
                        branches.append(ref)
                    }
                    references[ref] = SimpleReference(ref: ref, hash: hash, repository: repository)
                }
            }
        }
        
        self.references = references
        self.tags = tags
        self.branches = branches
    }
    
    subscript(ref: Ref) -> Reference? {
        if let reference = references[ref] {
            return reference
        }
        for key in references.keys {
            if key.path.hasSuffix(ref.path) {
                return references[key]
            }
        }
        return nil
    }
    
    func allBranches() -> [Reference] {
        return branches.flatMap { references[$0] }
    }
    
    func allTags() -> [Reference] {
        return tags.flatMap { references[$0] }
    }
    
}

// MARK: -

extension Repository {
    
    public var referenceStore: ReferenceStore {
        return ReferenceStore(repository: self)
    }
    
}
