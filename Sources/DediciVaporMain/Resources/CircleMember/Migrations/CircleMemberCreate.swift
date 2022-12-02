//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent

internal struct CircleMemberCreate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CircleMember.schema)
            .id()
            .field(CircleMember.FieldKeys.creationDate, .datetime, .required)
            .field(CircleMember.FieldKeys.lastModificationDate, .datetime, .required)
            .field(CircleMember.FieldKeys.userId, .uuid, .required)
            .field(CircleMember.FieldKeys.circleId, .uuid, .required)
            .field(CircleMember.FieldKeys.role, .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CircleMember.schema)
            .delete()
    }
}
