//
//  CommitWriter.swift
//  Git
//
//  Created by Jake Heiser on 9/8/16.
//
//

import Foundation
import FileKit

final public class CommitWriter: ObjectWriter {
    
    typealias Object = Commit
    
    public let treeHash: String
    public let parentHash: String?
    public let authorSignature: Signature
    public let committerSignature: Signature
    public let message: String
    public let repository: Repository
    
    public enum Error: Swift.Error {
        case unreadableIndex
        case unreadableHead
    }
    
    @discardableResult
    public static func commitCurrent(in repository: Repository, message: String) throws -> String {
        let treeHash = try TreeWriter.writeCurrent(in: repository)
        
        guard let head = repository.head else {
            throw Error.unreadableHead
        }
        
        let commitHash = try CommitWriter(treeHash: treeHash, parentHash: head.kind.hash, message: message, repository: repository).write()
        
        try head.updateUnderlying(to: commitHash, message: "commit: \(message)")
        
        return commitHash
    }
    
    public init(treeHash: String, parentHash: String?, message: String, repository: Repository, time: Date? = nil, timeZone: TimeZone? = nil) {
        self.treeHash = treeHash
        self.parentHash = parentHash
        guard let currentUser = Signature.currentUser(at: time, in: timeZone) else {
            fatalError("Couldn't form current user")
        }
        self.authorSignature = currentUser
        self.committerSignature = currentUser
        self.message = message
        self.repository = repository
    }
    
    func generateContentData() throws -> Data {
        let dataWriter = DataWriter()
        try dataWriter.write(ascii: "tree \(treeHash)\n")
        if let parentHash = parentHash {
            try dataWriter.write(ascii: "parent \(parentHash)\n")
        }
        try dataWriter.write(ascii: "author \(authorSignature)\n")
        try dataWriter.write(ascii: "committer \(committerSignature)\n")
        try dataWriter.write(ascii: "\n")
        try dataWriter.write(ascii: message)
        try dataWriter.write(ascii: "\n")
        
        return dataWriter.data
    }
    
}
