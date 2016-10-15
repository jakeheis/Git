import FileKit

class TestRepositories {
    
    static let repositoryLocation = "/Users/jakeheiser/Documents/Swift/Git/Tests/Repositories"
    static let realRepositoryLocation = repositoryLocation + "/Real"
    
    enum RepositoryType {
        case basic
        case packed
        case emptyObjects
        
        fileprivate var path: String {
            switch self {
            case .basic: return repositoryLocation + "/Basic"
            case .packed: return repositoryLocation + "/Packed"
            case .emptyObjects: return repositoryLocation + "/EmptyObjects"
            }
        }
    }
    
    static func repository(_ type: RepositoryType) -> Path {
        let originalPath = Path(rawValue: type.path)
        let newPath = moveRepository(at: originalPath)
        return newPath
    }
    
    static func reset() {
        for path in Path(rawValue: realRepositoryLocation) {
            if path.isDirectory {
                try! path.deleteFile()
            }
        }
    }
    
    // MARK: -
    
    private static func moveRepository(at path: Path) -> Path {
        let newPath = path.parent + "Real" + path.fileName
        if newPath.exists {
            return newPath
        }
        try! path.copyFileToPath(newPath)
        try! (newPath + "Git").moveFileToPath(newPath + ".git")
        return newPath
    }
    
}
