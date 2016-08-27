import Darwin.C
import SwiftCLI
import FileKit
import Core

Path.Current = "/Users/jakeheiser/Documents/Swift/initgit"

let r = Repository(path: Path.Current)!

print(r.packfiles)

//let bytes: [UInt8] = [0x10, 0xaa, 0x12, 0x14]



//print(bytes.bitIntValue())
//
//var int: Int = 0
//for i in 0 ..< bytes.count {
//    print(Int(bytes[bytes.count - i - 1]))
//    int |= Int(bytes[bytes.count - i - 1]) << (i * 8)
//    print(int)
//}
//print(int)
//
//CLI.setup(name: "Git")
//
//let plumbing: [RepositoryCommand] = [
//    CatFileCommand(),
//    LsFilesCommand(),
//    LsTreeCommand()
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
//let result = CLI.go()
//exit(result)
