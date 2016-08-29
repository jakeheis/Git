import Darwin.C
import SwiftCLI
import FileKit
import Core

Path.Current = "/Users/jakeheiser/Documents/Swift/initgit copy"

let r = Repository(path: Path.Current)!

//print(r.packfiles)

CLI.setup(name: "Git")

let plumbing: [RepositoryCommand] = [
    CatFileCommand(),
    LsFilesCommand(),
    LsTreeCommand(),
    VerifyPackCommand()
]

let porcelain: [RepositoryCommand] = [
    BranchCommand(),
    LogCommand(),
    StatusCommand(),
    TagCommand()
]

CLI.register(commands: plumbing)
CLI.register(commands: porcelain)

let result = CLI.debugGo(with: "git cat-file -p 5c55fef977975f927c3e7ada2b3a35e837e59ce6")
exit(result)

// xcodebuild -project Git.xcodeproj -scheme Git clean build | grep [1-9].[0-9]ms | sort -nr > culprits.txt
