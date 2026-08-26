// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "spotify_sdk_ios",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "spotify-sdk-ios", targets: ["spotify_sdk_ios"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/spotify/ios-sdk.git",
            exact: "5.0.1"
        )
    ],
    targets: [
        .target(
            name: "spotify_sdk_ios",
            dependencies: [
                .product(name: "SpotifyiOS", package: "ios-sdk")
            ],
            path: "Classes"
        )
    ]
)
