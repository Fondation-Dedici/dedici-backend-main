//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent

internal struct CircleInvitationCreate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CircleInvitation.schema)
            .id()
            .field(CircleInvitation.FieldKeys.creationDate, .datetime, .required)
            .field(CircleInvitation.FieldKeys.lastModificationDate, .datetime, .required)
            .field(CircleInvitation.FieldKeys.expirationDate, .datetime, .required)
            .field(CircleInvitation.FieldKeys.issuerUserId, .uuid, .required)
            .field(CircleInvitation.FieldKeys.issuerIdentityId, .uuid, .required)
            .field(CircleInvitation.FieldKeys.circleId, .uuid, .required)
            .field(CircleInvitation.FieldKeys.activationCode, .string, .required)
            .field(CircleInvitation.FieldKeys.activationDate, .date)
            .field(CircleInvitation.FieldKeys.activationUserId, .uuid)
            .field(CircleInvitation.FieldKeys.activationIdentityId, .uuid)
            .unique(on: CircleInvitation.FieldKeys.activationCode)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CircleInvitation.schema)
            .delete()
    }
}
