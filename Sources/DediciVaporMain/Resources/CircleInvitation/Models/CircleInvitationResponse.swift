//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct CircleInvitationResponse: ResourceRequestResponse {
    struct Activation: Content {
        var date: Date
        var userId: UUIDv4
        var identityId: UUIDv4
    }

    var id: UUIDv4
    var creationDate: Date
    var lastModificationDate: Date
    var expirationDate: Date
    var issuerIdentityId: UUIDv4
    var circleId: UUIDv4
    var activationCode: String
    var activation: Activation?

    init(from resource: CircleInvitation, and _: Request) throws {
        self.id = try .init(value: resource.id.require())
        self.creationDate = resource.creationDate
        self.expirationDate = try resource.expirationDate.require()
        self.lastModificationDate = resource.lastModificationDate
        self.issuerIdentityId = try .init(value: resource.issuerIdentityId)
        self.circleId = try .init(value: resource.circleId)
        self.activationCode = resource.activationCode

        if resource.activationDate != nil || resource.activationUserId != nil || resource.activationIdentityId != nil {
            self.activation = .init(
                date: try resource.activationDate.require(),
                userId: try .init(value: resource.activationUserId.require()),
                identityId: try .init(value: resource.activationIdentityId.require())
            )
        }
    }

    static func make(from resource: CircleInvitation, and request: Request) throws -> EventLoopFuture<Self> {
        let response = try Self(from: resource, and: request)
        return request.eventLoop.future(response)
    }
}
