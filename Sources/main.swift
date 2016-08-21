import Foundation

let repo = Repository(path: "/Users/jakeheiser/Documents/Swift/SwiftCLI")

let data = NSData(contentsOfFile: "/Users/jakeheiser/Documents/Swift/testgit/.git/objects/40/556ad302e9b09fc0be77e6313b3bf6229aab44")!

let uncompressed = try! data.gzipUncompressed()
print(data.length)
print(uncompressed.length)
// print(String(data: uncompressed as Data, encoding: String.Encoding.utf8))

// print(repo)
// print(repo?.head)
// print(repo?.tags)
// arg()
