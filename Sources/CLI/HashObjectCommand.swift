//
//  HashObjectCommand.swift
//  Git
//
//  Created by Jake Heiser on 9/3/16.
//
//

import Core
import SwiftCLI
import FileKit

class HashObjectCommand: RepositoryCommand {
    
    let name = "hash-object"
    let signature = "<path>"
    let shortDescription = "Hashes object at the given path"
    
    var write = false
    
    func setupOptions(options: OptionRegistry) {
        options.add(flags: ["-w"]) {
            self.write = true
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        let rawPath = arguments.requiredArgument("path")
        guard let repository = repository else {
            throw CLIError.error("Repository could not be read")
        }
        
        let blobWriter = BlobWriter(file: Path(rawPath), repository: repository)
        
        let blob: Blob
        do {
            blob = write ? try blobWriter.write() : try blobWriter.createWithoutWrite()
        } catch {
            throw CLIError.error("Could not hash object")
        }
        print(blob.hash)
    }
    
}
