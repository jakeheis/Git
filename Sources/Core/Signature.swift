//
//  Signature.swift
//  Git
//
//  Created by Jake Heiser on 8/22/16.
//
//

import Foundation

public class Signature {
    
    public let name: String
    public let email: String
    public let time: Date
    public let timeZone: TimeZone
    
    init(signature: String) {
        var words = signature.components(separatedBy: " ")
        
        let timeZoneIdentifier = "GMT" + words.removeLast()
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier),
            let seconds = TimeInterval(words.removeLast()) else {
                fatalError("Corrupt signature: \(signature)")
        }
        
        self.timeZone = timeZone
        self.time = Date(timeIntervalSince1970: seconds)
        let email = words.removeLast()
        self.email = email.substring(with: email.index(after: email.startIndex) ..< email.index(before: email.endIndex))
        self.name = words.joined(separator: " ")
    }
    
}

extension Signature: CustomStringConvertible {
    
    public var description: String {
        return "\(name) <\(email)> \(time) \(timeZone)"
    }
    
}
