// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpeechTranscriber",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SpeechTranscriber",
            targets: ["SpeechTranscriber"]),
    ],
    targets: [
        .target(
            name: "SpeechTranscriber"),
        .testTarget(
            name: "SpeechTranscriberTests",
            dependencies: ["SpeechTranscriber"]),
    ]
)
