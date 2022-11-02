// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "LMGeocoderSwift",
    platforms: [
        .macOS(.v10_10),
        .macCatalyst(.v13),
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v2)
    ],
    products: [
        .library(
            name: "LMGeocoderSwift",
            targets: ["LMGeocoderSwift"]
        )
    ],
    targets: [
        .target(
            name: "LMGeocoderSwift",
            path: "LMGeocoderSwift/Classes"
        )
    ]
)