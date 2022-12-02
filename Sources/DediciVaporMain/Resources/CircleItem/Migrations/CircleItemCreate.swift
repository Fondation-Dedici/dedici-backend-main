//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent

internal struct CircleItemCreate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CircleItem.schema)
            .id()
            .field(CircleItem.FieldKeys.creationDate, .datetime, .required)
            .field(CircleItem.FieldKeys.lastModificationDate, .datetime, .required)
            .field(CircleItem.FieldKeys.deletionDate, .datetime)
            .field(CircleItem.FieldKeys.ownerId, .uuid)
            .field(CircleItem.FieldKeys.circleId, .uuid, .required)
            .field(CircleItem.FieldKeys.versionTag, .uuid, .required)
            .field(CircleItem.FieldKeys.versionIssuerIdentityId, .uuid, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CircleItem.schema)
            .delete()
    }
}
