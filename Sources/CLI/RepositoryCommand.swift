//
//  RepositoryCommand.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

import Core
import SwiftCLI
import FileKit

protocol RepositoryCommand: OptionCommand {}

extension RepositoryCommand {
    
    var repository: Repository? {
        return Repository(path: Path.current)
    }
    
}
