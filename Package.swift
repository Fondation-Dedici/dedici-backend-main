// swift-tools-version:5.7

import Foundation
import PackageDescription

internal var packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/vapor/vapor", .upToNextMajor(from: "4.65.1")),
    .package(url: "https://github.com/vapor/fluent", .upToNextMajor(from: "4.5.0")),
    .package(url: "https://github.com/vapor/fluent-mysql-driver", .upToNextMajor(from: "4.1.0")),
    .package(url: "https://github.com/vapor/fluent-sqlite-driver", .upToNextMajor(from: "4.2.0")),
    .package(url: "https://github.com/MihaelIsaev/FCM.git", .upToNextMajor(from: "2.7.0")),
    .package(url: "https://github.com/Fondation-Dedici/swift-dedici-vapor-toolbox", .upToNextMajor(from: "0.3.6")),
    .package(
        url: "https://github.com/Fondation-Dedici/swift-dedici-vapor-fluent-toolbox",
        .upToNextMajor(from: "0.2.2")
    ),
    .package(
        url: "https://github.com/Fondation-Dedici/swift-dedici-vapor-fluent-mysql-toolbox",
        .upToNextMajor(from: "0.2.2")
    ),
]

internal var targetDependencies: [Target.Dependency] = [
    .product(name: "Fluent", package: "fluent"),
    .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
    .product(name: "Vapor", package: "vapor"),
    .product(name: "FCM", package: "FCM"),
    .product(name: "DediciVaporToolbox", package: "swift-dedici-vapor-toolbox"),
    .product(name: "DediciVaporFluentToolbox", package: "swift-dedici-vapor-fluent-toolbox"),
    .product(name: "DediciVaporFluentMySQLToolbox", package: "swift-dedici-vapor-fluent-mysql-toolbox"),
]

#if canImport(CryptoKit)
targetDependencies.append(.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"))
#endif

internal let package = Package(
    name: "dedici-backend-main",
    platforms: [
        .macOS(.v10_15),
    ],
    dependencies: packageDependencies,
    targets: [
        .target(
            name: "DediciVaporMain",
            dependencies: targetDependencies,
            swiftSettings: [
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
            ]
        ),
        .executableTarget(
            name: "Run",
            dependencies: [.target(name: "DediciVaporMain")]
        ),
    ]
)
