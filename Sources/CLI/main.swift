import Darwin.C
import SwiftCLI
import FileKit
import Core

Path.Current = "/Users/jakeheiser/Documents/Swift/SwiftCLI"

CLI.setup(name: "Git")

let plumbing: [RepositoryCommand] = [
    CatFileCommand(),
    LsFilesCommand()
]

let porcelain: [RepositoryCommand] = [
    BranchCommand(),
    LogCommand(),
    TagCommand()
]

CLI.register(commands: plumbing)
CLI.register(commands: porcelain)

let result = CLI.debugGo(with: "git tag")
exit(result)
