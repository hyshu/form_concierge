// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FormConciergeSwiftUI",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "FormConciergeSwiftUI",
            targets: ["FormConciergeSwiftUI"]
        )
    ],
    targets: [
        .target(name: "FormConciergeSwiftUI"),
        .testTarget(
            name: "FormConciergeSwiftUITests",
            dependencies: ["FormConciergeSwiftUI"]
        )
    ]
)
