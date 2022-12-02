//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Vapor

internal final class CircleItem: ResourceModel {
    static let schema = "circle_items"

    @ID(key: FieldKeys.id)
    var id: UUID?

    @Field(key: FieldKeys.creationDate)
    var creationDate: Date

    @Field(key: FieldKeys.lastModificationDate)
    var lastModificationDate: Date

    @Field(key: FieldKeys.deletionDate)
    var deletionDate: Date?

    @Field(key: FieldKeys.ownerId)
    var ownerId: UUID?

    @Field(key: FieldKeys.circleId)
    var circleId: UUID

    @Field(key: FieldKeys.versionTag)
    var versionTag: UUID

    @Field(key: FieldKeys.versionIssuerIdentityId)
    var versionIssuerIdentityId: UUID

    init() {}

    init(
        id: IDValue? = nil,
        ownerId: UUIDv4?,
        circleId: UUIDv4,
        versionTag: UUIDv4,
        versionIssuerIdentityId: UUIDv4
    ) {
        self.id = id
        self.deletionDate = nil
        self.ownerId = ownerId?.value
        self.circleId = circleId.value
        self.versionTag = versionTag.value
        self.versionIssuerIdentityId = versionIssuerIdentityId.value
    }
}

extension CircleItem {
    enum FieldKeys {
        static let id: FieldKey = .id
        static let creationDate: FieldKey = .string("creation_date")
        static let lastModificationDate: FieldKey = .string("last_modification_date")
        static let deletionDate: FieldKey = .string("deletion_date")
        static let ownerId: FieldKey = .string("owner_id")
        static let circleId: FieldKey = .string("circle_id")
        static let versionTag: FieldKey = .string("version_tag")
        static let versionIssuerIdentityId: FieldKey = .string("version_issuer_identity_id")
    }
}

extension CircleItem: ModelCanBeDeleted {
    var deletionDateField: FieldProperty<CircleItem, Date?> { $deletionDate }
}

extension CircleItem: HasDefaultResponse {
    typealias DefaultResponse = CircleItemResponse
}

extension CircleItem: HasDefaultCreateOneBody {
    typealias DefaultCreateOneBody = CircleItemNew
}
