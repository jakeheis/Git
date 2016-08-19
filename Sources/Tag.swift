import Foundation
import FileKit

struct Tag {
    let name: String
    let hash: String
    
    init?(path: Path) {
        guard let hash = try? String.readFromPath(path) else {
            return nil
        }
        
        self.name = path.fileName
        self.hash = hash.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

extension Repository {
    
    var tags: [Tag] {
        get {
            let tagsDirectory = subpath(with: "refs/tags")
            return tagsDirectory.flatMap { Tag(path: $0) }
        }
    }
    
}