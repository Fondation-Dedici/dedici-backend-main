//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Vapor

internal final class Circle: ResourceModel {
    static let schema = "circles"

    @ID(key: FieldKeys.id)
    var id: UUID?

    @Field(key: FieldKeys.creationDate)
    var creationDate: Date

    @Field(key: FieldKeys.lastModificationDate)
    var lastModificationDate: Date

    @Field(key: FieldKeys.deletionDate)
    var deletionDate: Date?

    @Field(key: FieldKeys.publicContent)
    var publicContent: Data?

    init() {}

    init(
        id: IDValue? = nil,
        deletionDate: Date? = nil,
        publicContent: Data? = nil
    ) {
        self.id = id
        self.deletionDate = deletionDate
        self.publicContent = publicContent
    }
}

extension Circle {
    enum FieldKeys {
        static let id: FieldKey = .id
        static let creationDate: FieldKey = .string("creation_date")
        static let lastModificationDate: FieldKey = .string("last_modification_date")
        static let deletionDate: FieldKey = .string("deletion_date")
        static let publicContent: FieldKey = .string("public_content")
    }
}

extension Circle: ModelCanBeDeleted {
    var deletionDateField: FieldProperty<Circle, Date?> { $deletionDate }
}

extension Circle: HasDefaultResponse {
    typealias DefaultResponse = CircleResponse
}

extension Circle: HasDefaultCreateOneBody {
    typealias DefaultCreateOneBody = CircleNew
}
