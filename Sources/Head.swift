import Foundation
import FileKit

class Head {
   
    enum Kind {
        case hash(String)
        case reference(Reference)
    }
    
    let kind: Kind
    let repository: Repository
    
    var commit: Commit? {
        switch kind {
        case let .hash(hash): return repository.objectStore[hash] as? Commit
        case let .reference(reference): return reference.object as? Commit
        }
    }
    
    convenience init?(repository: Repository) {
        self.init(path: repository.subpath(with: "HEAD"), repository: repository)
    }
    
    convenience init?(path: Path, repository: Repository) {
        guard let contents = try? String.readFromPath(path) else {
            return nil
        }
        
        self.init(text: contents, repository: repository)
    }
    
    init(text: String, repository: Repository) {
        if text.hasPrefix("ref: "), let refSpace = text.characters.index(of: " ") {
            let startIndex = text.index(refSpace, offsetBy: 1)
            let endIndex = text.characters.index(of: "\n") ?? text.endIndex
            let refText = text.substring(with: startIndex ..< endIndex)
            
            guard let reference = Reference(path: repository.subpath(with: refText), repository: repository) else {
                fatalError("Broken HEAD: \(refText)")
            }
            self.kind = .reference(reference)
        } else {
            self.kind = .hash(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        self.repository = repository
    }
    
}

extension Head: CustomStringConvertible {
    
    var description: String {
        return "HEAD: \(commit?.hash ?? "(none)")"
    }
    
}

extension Repository {
    
    var head: Head? {
        get {
            return Head(repository: self)
        }
    }
    
}
