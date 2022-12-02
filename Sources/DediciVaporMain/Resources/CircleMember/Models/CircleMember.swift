//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Vapor

internal final class CircleMember: ResourceModel {
    static let schema = "circle_members"

    @ID(key: FieldKeys.id)
    var id: UUID?

    @Field(key: FieldKeys.creationDate)
    var creationDate: Date

    @Field(key: FieldKeys.lastModificationDate)
    var lastModificationDate: Date

    @Field(key: FieldKeys.userId)
    var userId: UUID

    @Field(key: FieldKeys.circleId)
    var circleId: UUID

    @Field(key: FieldKeys.role)
    var role: CircleRole

    init() {}

    init(
        id: IDValue? = nil,
        userId: UUID,
        circleId: UUID,
        role: CircleRole
    ) {
        self.id = id
        self.userId = userId
        self.circleId = circleId
        self.role = role
    }
}

extension CircleMember {
    enum FieldKeys {
        static let id: FieldKey = .id
        static let creationDate: FieldKey = .string("creation_date")
        static let lastModificationDate: FieldKey = .string("last_modification_date")
        static let userId: FieldKey = .string("user_id")
        static let circleId: FieldKey = .string("circle_id")
        static let role: FieldKey = .string("role")
    }
}

extension CircleMember: HasDefaultResponse {
    typealias DefaultResponse = CircleMemberResponse
}
