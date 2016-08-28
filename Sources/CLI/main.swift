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

let result = CLI.debugGo(with: "git verify-pack .git/objects/pack/pack-33f6348e282fa3392dcdf4a016faa8ae85f9e242.idx")
exit(result)

// xcodebuild -project Git.xcodeproj -scheme Git clean build | grep [1-9].[0-9]ms | sort -nr > culprits.txt
