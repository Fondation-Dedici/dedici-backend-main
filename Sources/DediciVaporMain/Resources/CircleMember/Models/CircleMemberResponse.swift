//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct CircleMemberResponse: ResourceRequestResponse {
    var id: UUIDv4
    var creationDate: Date
    var lastModificationDate: Date
    var userId: UUIDv4
    var circleId: UUIDv4
    var role: CircleRole

    init(from resource: CircleMember, and _: Request) throws {
        self.id = try .init(value: resource.id.require())
        self.creationDate = resource.creationDate
        self.lastModificationDate = resource.lastModificationDate
        self.userId = try .init(value: resource.userId)
        self.circleId = try .init(value: resource.circleId)
        self.role = resource.role
    }

    static func make(from resource: CircleMember, and request: Request) throws -> EventLoopFuture<Self> {
        let response = try Self(from: resource, and: request)
        return request.eventLoop.future(response)
    }
}
