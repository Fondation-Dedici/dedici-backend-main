//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent

internal struct IdentityCreate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Identity.schema)
            .id()
            .field(Identity.FieldKeys.creationDate, .datetime, .required)
            .field(Identity.FieldKeys.lastModificationDate, .datetime, .required)
            .field(Identity.FieldKeys.userId, .uuid, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Identity.schema)
            .delete()
    }
}
