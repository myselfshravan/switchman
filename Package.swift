// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Switchman",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SwitchmanCore", targets: ["SwitchmanCore"]),
        .executable(name: "switchman", targets: ["switchman-cli"]),
        .executable(name: "SwitchmanApp", targets: ["SwitchmanApp"]),
    ],
    targets: [
        .target(name: "SwitchmanCore", resources: [.copy("Resources/public_suffix_list.dat")]),
        .executableTarget(name: "switchman-cli", dependencies: ["SwitchmanCore"]),
        .executableTarget(name: "SwitchmanApp", dependencies: ["SwitchmanCore"]),
        .testTarget(name: "SwitchmanCoreTests", dependencies: ["SwitchmanCore"]),
        .testTarget(name: "SwitchmanCLITests", dependencies: ["switchman-cli"]),
    ]
)
