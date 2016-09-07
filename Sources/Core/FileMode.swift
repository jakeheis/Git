//
//  FileMode.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

public enum FileMode: String { // Don't use Int because these aren't base 10 numbers
    case directory = "40000"
    case blob = "100644"
    case executable = "100755"
    case link = "120000"
    case permissionedLink = "120755"
    
    public var intText: String {
        if self == .directory {
            return "0" + rawValue
        }
        return String(rawValue)
    }
    
    public var name: String {
        switch self {
        case .directory: return "tree"
        case .blob, .link, .executable, .permissionedLink: return "blob"
        }
    }
    
    public func split() -> (objectType: ObjectType, unixPermission: UnixPermission) {
        let modeValue = Int(rawValue, radix: 8)!
        
        let objectType = modeValue >> 12
        let unixPermission = modeValue & 0x1FF
        
        return (ObjectType(rawValue: objectType)!, UnixPermission(rawValue: unixPermission)!)
    }
    
    public enum ObjectType: Int {
        case regularFile = 0b1000
        case symbolicLink = 0b1010
        case gitLink = 0b1110
    }
    
    public enum UnixPermission: Int {
        case zero = 0
        case sixFourtyFour = 0o644
        case sevenFiftyFive = 0o755
    }
}
