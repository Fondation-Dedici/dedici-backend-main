//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct CircleItemResponse: ResourceRequestResponse {
    typealias Resource = CircleItem

    var id: UUIDv4
    var creationDate: Date
    var lastModificationDate: Date
    var deletionDate: Date?
    var circleId: UUIDv4
    var versionTag: UUIDv4
    var ownerId: UUIDv4?

    init(from resource: CircleItem, and _: Request) throws {
        self.id = try .init(value: resource.id.require())
        self.creationDate = resource.creationDate
        self.lastModificationDate = resource.lastModificationDate
        self.deletionDate = resource.deletionDate
        self.circleId = try .init(value: resource.circleId)
        self.versionTag = try .init(value: resource.versionTag)
        self.ownerId = try resource.ownerId.flatMap(UUIDv4.init)
    }

    static func make(from resource: CircleItem, and request: Request) throws -> EventLoopFuture<Self> {
        let response = try Self(from: resource, and: request)
        return request.eventLoop.future(response)
    }
}
