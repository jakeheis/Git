import Darwin.C
import SwiftCLI
import FileKit

Path.Current = "/Users/jakeheiser/Documents/Swift/Git"

CLI.setup(name: "Git")

let plumbing: [RepositoryCommand] = [
    CatFileCommand(),
    LsFilesCommand()
]

let porcelain: [RepositoryCommand] = [
    LogCommand()
]

CLI.register(commands: plumbing)
CLI.register(commands: porcelain)

let result = CLI.debugGo(with: "git ls-files")
exit(result)
