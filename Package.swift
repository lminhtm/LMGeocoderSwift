// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "LMGeocoderSwift",
    platforms: [
        .macOS(.v13),
        .macCatalyst(.v13),
        .iOS(.v11),
        .tvOS(.v11),
        .watchOS(.v4)
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
