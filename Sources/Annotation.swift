//
//  Annotation.swift
//  Git
//
//  Created by Jake Heiser on 8/22/16.
//
//

import Foundation

class Annotation {
    
    let text: String
    
    init(annotation: String) {
        self.text = annotation
    }
    
}

extension Annotation: CustomStringConvertible {
    
    var description: String {
        return text
    }
    
}
