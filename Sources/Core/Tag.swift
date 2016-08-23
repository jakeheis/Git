import Foundation
import FileKit

public class Tag: Reference {
    
}

extension Repository {
    
    public var tags: [Tag] {
        get {
            let tagsDirectory = subpath(with: "refs/tags")
            return tagsDirectory.flatMap { Tag(path: $0, repository: self) }
        }
    }
    
}
