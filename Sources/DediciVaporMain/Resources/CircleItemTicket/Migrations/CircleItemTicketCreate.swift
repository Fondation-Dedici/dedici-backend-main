//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent

internal struct CircleItemTicketCreate: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CircleItemTicket.schema)
            .id()
            .field(CircleItemTicket.FieldKeys.creationDate, .datetime, .required)
            .field(CircleItemTicket.FieldKeys.lastModificationDate, .datetime, .required)
            .field(CircleItemTicket.FieldKeys.itemId, .uuid, .required)
            .field(CircleItemTicket.FieldKeys.identityId, .uuid, .required)
            .field(CircleItemTicket.FieldKeys.versionTag, .uuid, .required)
            .field(CircleItemTicket.FieldKeys.assigneeId, .uuid)
            .field(CircleItemTicket.FieldKeys.assignmentExpirationDate, .date)
            .field(CircleItemTicket.FieldKeys.sharingConfirmationDate, .date)
            .unique(
                on: CircleItemTicket.FieldKeys.itemId,
                CircleItemTicket.FieldKeys.versionTag,
                CircleItemTicket.FieldKeys.identityId
            )
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CircleItemTicket.schema)
            .delete()
    }
}
