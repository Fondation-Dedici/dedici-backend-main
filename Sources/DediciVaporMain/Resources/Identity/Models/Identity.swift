//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Vapor

internal final class Identity: ResourceModel {
    static let schema = "identities"

    @ID(key: FieldKeys.id)
    var id: UUID?

    @Field(key: FieldKeys.creationDate)
    var creationDate: Date

    @Field(key: FieldKeys.lastModificationDate)
    var lastModificationDate: Date

    @Field(key: FieldKeys.userId)
    var ownerId: UUID

    init() {}

    init(
        id: IDValue? = nil,
        ownerId: UUID
    ) {
        self.id = id
        self.ownerId = ownerId
    }
}

extension Identity {
    enum FieldKeys {
        static let id: FieldKey = .id
        static let creationDate: FieldKey = .string("creation_date")
        static let lastModificationDate: FieldKey = .string("last_modification_date")
        static let userId: FieldKey = .string("user_id")
    }
}
