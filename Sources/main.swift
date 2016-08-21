import Foundation

let repo = Repository(path: "/Users/jakeheiser/Documents/Swift/Git")!

print(repo.objects)

let data = NSData(contentsOfFile: "/Users/jakeheiser/Documents/Swift/SwiftCLI/.git/objects/fa/64385a6cc5c47c477f3f7c71758b29c3ca4abe")!

let uncompressed = try! data.gzipUncompressed() as Data

var unparsed = String(data: uncompressed, encoding: .ascii)!

var byteCounter = 0

let headerIndex = unparsed.characters.index(of: "\0")!
let header = unparsed.substring(to: headerIndex)
byteCounter += unparsed.distance(from: unparsed.startIndex, to: headerIndex) + 1
unparsed = unparsed.substring(from: unparsed.index(headerIndex, offsetBy: 1))

print(header)

while !unparsed.isEmpty {
    let modeIndex = unparsed.characters.index(of: " ")!
    let mode = unparsed.substring(to: modeIndex)
    byteCounter += unparsed.distance(from: unparsed.startIndex, to: modeIndex) + 1
    unparsed = unparsed.substring(from: unparsed.index(modeIndex, offsetBy: 1))
    
    let nameIndex = unparsed.characters.index(of: "\0")!
    let name = unparsed.substring(to: nameIndex)
    byteCounter += unparsed.distance(from: unparsed.startIndex, to: nameIndex) + 1
    unparsed = unparsed.substring(from: unparsed.index(nameIndex, offsetBy: 1))
    
    let hashIndex = unparsed.index(unparsed.startIndex, offsetBy: 20)
    let hashBytes = uncompressed.subdata(in: byteCounter..<(byteCounter + 20))
    unparsed = unparsed.substring(from: hashIndex)
    byteCounter += 20
    
    let hash = NSMutableString()
    for i in 0..<hashBytes.count {
        hash.append(NSString(format: "%02x", hashBytes[i]) as String)
    }

    print(mode, hash, name)
}

// print(repo)
// print(repo?.head)
// print(repo?.tags)
// arg()
