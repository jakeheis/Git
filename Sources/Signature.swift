//
//  Signature.swift
//  Git
//
//  Created by Jake Heiser on 8/22/16.
//
//

import Foundation

class Signature {
    
    let name: String
    let email: String
    let time: Date
    let timeZone: TimeZone
    
    init(signature: String) {
        var words = signature.components(separatedBy: " ")
        
        guard let timeZone = TimeZone(stringOffset: words.removeLast()),
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
    
    var description: String {
        return "\(name) <\(email)> \(time) \(timeZone)"
    }
    
}

extension TimeZone {
    
    init?(stringOffset: String) {
        let signBreakIndex = stringOffset.index(after: stringOffset.startIndex)
        let hourBreakIndex = stringOffset.index(stringOffset.startIndex, offsetBy: 3)
        
        let sign = stringOffset.hasPrefix("-") ? -1 : 1
        let hours = Int(stringOffset.substring(with: signBreakIndex ..< hourBreakIndex)) ?? 0
        let minutes = Int(stringOffset.substring(from: hourBreakIndex)) ?? 0
        
        let secondOffset = (hours * 3600 + minutes * 60) * sign
        self.init(secondsFromGMT: secondOffset)
    }
    
}
