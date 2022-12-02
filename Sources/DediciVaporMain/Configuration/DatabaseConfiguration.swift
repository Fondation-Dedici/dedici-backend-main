//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Fluent
import FluentMySQLDriver
import Foundation
import Vapor
#if canImport(FluentSQLiteDriver)
import FluentSQLiteDriver
#endif

internal struct DatabaseConfiguration: AppConfiguration {
    func configure(_ application: Application) throws {
        let isDummy = (try? Environment.require(key: "DATABASE_IS_IN_MEMORY", using: { Bool($0) })) ?? false
        guard !isDummy else {
            #if canImport(FluentSQLiteDriver)
            let config = SQLiteConfiguration(storage: .memory(identifier: "development"), enableForeignKeys: false)
            application.databases.use(.sqlite(config, maxConnectionsPerEventLoop: 20), as: .sqlite)
            return
            #else
            fatalError("Failed to initialize memory db")
            #endif
        }

        let host = try Environment.require(key: "DATABASE_HOST")
        let port = try Environment.require(key: "DATABASE_PORT", using: { Int($0) })
        let username = try Environment.require(key: "DATABASE_USERNAME")
        let password = try Environment.require(key: "DATABASE_PASSWORD")
        let name = try Environment.require(key: "DATABASE_NAME")
        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
        tlsConfiguration.certificateVerification = .none

        application.databases.use(.mysql(
            hostname: host,
            port: port,
            username: username,
            password: password,
            database: name,
            tlsConfiguration: tlsConfiguration,
            maxConnectionsPerEventLoop: 20
        ), as: .mysql)
    }
}
