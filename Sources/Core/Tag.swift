import Foundation
import FileKit

public class Tag: Reference {
    
}

extension Repository {
    
    public var tags: [Tag] {
        get {
            let tagRefs = "refs/tags"
            let tagsDirectory = subpath(with: tagRefs)
            return tagsDirectory.flatMap { Tag(ref: tagRefs + "/" + $0.fileName, repository: self) }
        }
    }
    
}
