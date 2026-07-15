// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "FormConcierge",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
  ],
  products: [
    .library(
      name: "FormConciergeSwiftUI",
      targets: ["FormConciergeSwiftUI"]
    ),
    .library(
      name: "FormConciergeUIKit",
      targets: ["FormConciergeUIKit"]
    ),
  ],
  targets: [
    .target(
      name: "FormConciergeSwiftUI",
      path: "apple/Sources/FormConciergeSwiftUI"
    ),
    .target(
      name: "FormConciergeUIKit",
      dependencies: ["FormConciergeSwiftUI"],
      path: "apple/Sources/FormConciergeUIKit"
    ),
    .testTarget(
      name: "FormConciergeSwiftUITests",
      dependencies: ["FormConciergeSwiftUI"],
      path: "apple/Tests/FormConciergeSwiftUITests"
    ),
  ]
)
