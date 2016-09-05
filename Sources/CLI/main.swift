import Darwin.C
import SwiftCLI
import FileKit
import Core

Path.Current = "/Users/jakeheiser/Documents/Swift/Git"
//Path.Current = "/Users/jakeheiser/Documents/Apps/Git Implementations/git"

let r = Repository(path: Path.Current)!

let object = r.objectStore["0d3e989b88ea57557338cdb4b2ac1382e1309899"]!
try! object.write()

//CLI.setup(name: "Git")
//
//let plumbing: [RepositoryCommand] = [
//    CatFileCommand(),
//    HashObjectCommand(),
//    LsFilesCommand(),
//    LsTreeCommand(),
//    VerifyPackCommand()
//]
//
//let porcelain: [RepositoryCommand] = [
//    BranchCommand(),
//    LogCommand(),
//    StatusCommand(),
//    TagCommand()
//]
//
//CLI.register(commands: plumbing)
//CLI.register(commands: porcelain)
//
//let result = CLI.debugGo(with: "git hash-object Package.swift")
//exit(result)

// xcodebuild -project Git.xcodeproj -scheme Git clean build | grep [1-9].[0-9]ms | sort -nr > culprits.txt
