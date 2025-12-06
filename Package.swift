// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "Fixtures",
  platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
  products: [
    .library(
      name: "Fixtures",
      targets: ["Fixtures"]
    ),
    .executable(
      name: "FixturesClient",
      targets: ["FixturesClient"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0-latest"),
  ],
  targets: [
    .macro(
      name: "FixturesMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "Fixtures",
      dependencies: ["FixturesMacros"]
    ),
    .executableTarget(
      name: "FixturesClient",
      dependencies: ["Fixtures"]
    ),
    .testTarget(
      name: "FixturesTests",
      dependencies: [
        "Fixtures",
      ]
    ),
    .testTarget(
      name: "FixturesMacrosTests",
      dependencies: [
        "FixturesMacros",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)
