import Foundation
import FileKit

final public class Tag: FolderedRefence {
    
    static let directory = "refs/tags"
    
}

// MARK: -

extension Repository {
    
    public var tags: [Tag] {
        var tags: [Tag] = []
        
        let tagsDirectory = subpath(with: Tag.directory)
        tags += tagsDirectory.flatMap { Tag(path: $0, repository: self) }
        
        if let packedReferences = packedReferences {
            tags += packedReferences.tags
        }
        
        return tags
    }
    
}
