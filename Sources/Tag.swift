import Foundation
import FileKit

class Tag: Reference {
    
}

extension Repository {
    
    var tags: [Tag] {
        get {
            let tagsDirectory = subpath(with: "refs/tags")
            return tagsDirectory.flatMap { Tag(path: $0, repository: self) }
        }
    }
    
}
