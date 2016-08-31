import Foundation
import FileKit

public class Tag: Reference {
    
    static let refPrefix = "refs/tags"
    
}

extension Repository {
    
    public var tags: [Tag] {
        var tags: [Tag] = []
        
        let tagsDirectory = subpath(with: Tag.refPrefix)
        tags += tagsDirectory.flatMap { Tag(path: $0, repository: self) }
        
        tags += Reference.packedRefs(in: self).flatMap { $0 as? Tag }
        
        return tags
    }
    
}
