// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "wallpaper",
  platforms: [
    .macOS("26.0"),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.6.2"),
  ],
  targets: [
    .executableTarget(
      name: "wallpaper",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "test",
      dependencies: [],
      path: "Tests"
    ),
  ],
  swiftLanguageModes: [.v5]
)
