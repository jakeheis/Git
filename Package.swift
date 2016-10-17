import PackageDescription

let package = Package(
    name: "Git",
    targets: [
        Target(name: "Core"),
        Target(name: "CLI", dependencies: [.Target(name: "Core")])
    ],
    dependencies: [
        .Package(url: "https://github.com/nvzqz/FileKit", majorVersion: 4, minor: 0),
        .Package(url: "https://github.com/jakeheis/SwiftCLI", majorVersion: 2, minor: 0),
        .Package(url: "https://github.com/onevcat/Rainbow", majorVersion: 2, minor: 0),
        .Package(url: "/Users/jakeheiser/Documents/Swift/Cncurses", majorVersion: 1, minor: 0),
        .Package(url: "/Users/jakeheiser/Documents/Swift/Czlib", majorVersion: 1, minor: 0),
        .Package(url: "https://github.com/IBM-Swift/CommonCrypto.git", majorVersion: 0, minor: 1)
    ],
    exclude: [
        "Tests/Repositories",
        "Tests/CLITests"
    ]
)
