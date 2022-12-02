//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Vapor

internal final class CircleItemTicket: ResourceModel {
    static let schema = "circle_item_tickets"

    @ID(key: FieldKeys.id)
    var id: UUID?

    @Field(key: FieldKeys.creationDate)
    var creationDate: Date

    @Field(key: FieldKeys.lastModificationDate)
    var lastModificationDate: Date

    @Field(key: FieldKeys.itemId)
    var itemId: UUID

    @Field(key: FieldKeys.versionTag)
    var versionTag: UUID

    @Field(key: FieldKeys.identityId)
    var identityId: UUID

    @Field(key: FieldKeys.assigneeId)
    var assigneeId: UUID?

    @Field(key: FieldKeys.assignmentExpirationDate)
    var assignmentExpirationDate: Date?

    @Field(key: FieldKeys.sharingConfirmationDate)
    var sharingConfirmationDate: Date?

    init() {}

    init(
        id: IDValue? = nil,
        itemId: UUIDv4,
        identityId: UUIDv4,
        versionTag: UUIDv4,
        assigneeId: UUIDv4? = nil,
        assignmentExpirationDate: Date? = nil,
        sharingConfirmationDate: Date? = nil
    ) {
        self.id = id
        self.itemId = itemId.value
        self.identityId = identityId.value
        self.versionTag = versionTag.value
        self.assigneeId = assigneeId?.value
        self.assignmentExpirationDate = assignmentExpirationDate
        self.sharingConfirmationDate = sharingConfirmationDate
    }
}

extension CircleItemTicket {
    enum FieldKeys {
        static let id: FieldKey = .id
        static let creationDate: FieldKey = .string("creation_date")
        static let lastModificationDate: FieldKey = .string("last_modification_date")
        static let itemId: FieldKey = .string("item_id")
        static let versionTag: FieldKey = .string("version_tag")
        static let identityId: FieldKey = .string("identity_id")
        static let assigneeId: FieldKey = .string("assignee_id")
        static let assignmentExpirationDate: FieldKey = .string("assignment_expiration_date")
        static let sharingConfirmationDate: FieldKey = .string("sharing_confirmation_date")
    }
}

extension CircleItemTicket: HasDefaultResponse {
    typealias DefaultResponse = CircleItemTicketResponse
}
