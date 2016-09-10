import PackageDescription

let package = Package(
    name: "Git",
    targets: [
        Target(name: "Core"),
        Target(name: "CLI", dependencies: [.Target(name: "Core")])
    ],
    dependencies: [
        .Package(url: "https://github.com/jakeheis/FileKit", Version(4, 0, 0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/jakeheis/SwiftCLI", Version(2, 0, 0, prereleaseIdentifiers: ["beta3"])),
        .Package(url: "/Users/jakeheiser/Documents/Swift/Cncurses", majorVersion: 1, minor: 0),
        .Package(url: "/Users/jakeheiser/Documents/Swift/Czlib", majorVersion: 1, minor: 0),
        .Package(url: "https://github.com/IBM-Swift/CommonCrypto.git", majorVersion: 0, minor: 1)
    ],
    exclude: [
        "Tests/Repositories"
    ]
)
