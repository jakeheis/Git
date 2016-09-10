//
//  Signature.swift
//  Git
//
//  Created by Jake Heiser on 8/22/16.
//
//

import Foundation

public struct Signature {
    
    public let name: String
    public let email: String
    public let time: Date
    public let timeZone: TimeZone
    
    public static func currentUser(at time: Date? = nil) -> Signature? {
        guard let name = Config.value(for: "name", in: "user"),
            let email = Config.value(for: "email", in: "user") else {
                return nil
        }
        return Signature(name: name, email: email, time: time ?? Date(), timeZone: TimeZone.current)
    }
    
    init(name: String, email: String, time: Date, timeZone: TimeZone) {
        self.name = name
        self.email = email
        self.time = time
        self.timeZone = timeZone
    }
    
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
        return "\(name) <\(email)> \(Int(round(time.timeIntervalSince1970))) \(timeZone.gitIdentifier)"
    }
    
}

extension Signature: Equatable {}

public func == (lhs: Signature, rhs: Signature) -> Bool {
    return lhs.name == rhs.name && lhs.email == rhs.email && lhs.time == rhs.time && lhs.timeZone.secondsFromGMT() == rhs.timeZone.secondsFromGMT()
}

// MARK: -

extension TimeZone {
    
    var gitIdentifier: String {
        var timeZoneOffset = secondsFromGMT() > 0 ? "" : "-"
        let hours = String(abs(secondsFromGMT() / 3600))
        if hours.characters.count == 1 {
            timeZoneOffset += "0"
        }
        timeZoneOffset += hours + "00"
        return timeZoneOffset
    }
    
}
