//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent

internal struct CircleCreate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Circle.schema)
            .id()
            .field(Circle.FieldKeys.creationDate, .datetime, .required)
            .field(Circle.FieldKeys.lastModificationDate, .datetime, .required)
            .field(Circle.FieldKeys.deletionDate, .datetime)
            .field(Circle.FieldKeys.publicContent, .data)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Circle.schema)
            .delete()
    }
}
