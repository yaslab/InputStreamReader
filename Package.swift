// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "InputStreamReader",
    targets: [
        Target(name: "InputStreamReader", dependencies: [])
    ],
    dependencies: [
        .Package(url: "https://github.com/yaslab/Iconv-support.git", majorVersion: 0, minor: 1)
    ]
)
