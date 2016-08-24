//
//  FileMode.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

public enum FileMode: Int {
    case directory = 40000
    case blob = 100644
    case executable = 100755
    case link = 120000
    
    var intText: String {
        if self == .directory {
            return "0" + String(rawValue)
        }
        return String(rawValue)
    }
    
    var name: String {
        switch self {
        case .directory: return "tree"
        case .blob, .link, .executable: return "blob"
        }
    }
    
    func split() -> (objectType: ObjectType, unixPermission: UnixPermission) {
        let modeValue = Int(String(rawValue), radix: 8)!
        
        let modeBinary = String(modeValue, radix: 2)
        let objectTypeBinary = modeBinary.substring(to: modeBinary.index(modeBinary.startIndex, offsetBy: 4))
        let objectTypeInt = Int(objectTypeBinary, radix: 2)!
        
        let unixPermissionBinary = modeBinary.substring(from: modeBinary.index(modeBinary.startIndex, offsetBy: 7))
        let unixPermissionInt = Int(unixPermissionBinary, radix: 2)!
        
        return (ObjectType(rawValue: objectTypeInt)!, UnixPermission(rawValue: unixPermissionInt)!)
    }
    
    public enum ObjectType: Int {
        case regularFile = 0b1000
        case symbolicLink = 0b1010
        case gitLink = 0b1110
    }
    
    public enum UnixPermission: Int {
        case zero = 0
        case sixFourtyFour = 0o644
        case sevemFiftyFive = 0o755
    }
}
