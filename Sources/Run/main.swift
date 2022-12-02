//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporMain
import Vapor

internal var env = try Environment.detect()
internal let app = Application(env)

// Setting up the logging system is kind of tricky for now. See: https://github.com/vapor/vapor/issues/2429
try LoggingSystem.bootstrap(from: &env)
app.logger = .init(label: app.logger.label)

internal let isDummy = (try? Environment.require(key: "DATABASE_IS_IN_MEMORY", using: { Bool($0) })) ?? false

defer { app.shutdown() }
try app.configure()

try app.autoMigrateUntilSuccess().wait()
if app.environment.name != "xcode" {
    try app.publishConfigUntilSuccess(config: PublicConfiguration.current, key: "main-api").wait()
}

try app.run()
