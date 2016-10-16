//
//  AliasCommands.swift
//  Git
//
//  Created by Jake Heiser on 10/16/16.
//
//

import Core
import SwiftCLI

class AliasCommands {
    
    static func loadAliases() {
        guard let group = Config.group(named: .alias) else {
            return
        }
        
        for entry in group.entries {
            CLI.alias(from: entry.key, to: entry.value)
        }
    }
    
}
