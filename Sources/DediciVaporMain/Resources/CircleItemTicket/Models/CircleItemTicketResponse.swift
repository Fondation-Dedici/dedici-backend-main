//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct CircleItemTicketResponse: ResourceRequestResponse {
    typealias Resource = CircleItemTicket

    struct Assignment: Content {
        let identityId: UUIDv4
        let expirationDate: Date
    }

    var id: UUIDv4
    var creationDate: Date
    var lastModificationDate: Date
    var itemId: UUIDv4
    var versionTag: UUIDv4
    var identityId: UUIDv4
    var assignment: Assignment?
    var sharingConfirmationDate: Date?

    init(from resource: CircleItemTicket, and _: Request) throws {
        self.id = try .init(value: resource.id.require())
        self.creationDate = resource.creationDate
        self.lastModificationDate = resource.lastModificationDate
        self.itemId = try .init(value: resource.itemId)
        self.versionTag = try .init(value: resource.versionTag)
        self.identityId = try .init(value: resource.identityId)
        if resource.assigneeId != nil || resource.assignmentExpirationDate != nil {
            self.assignment = .init(
                identityId: try .init(value: resource.assigneeId.require()),
                expirationDate: try resource.assignmentExpirationDate.require()
            )
        }
        self.sharingConfirmationDate = resource.sharingConfirmationDate
    }

    static func make(from resource: CircleItemTicket, and request: Request) throws -> EventLoopFuture<Self> {
        let response = try Self(from: resource, and: request)
        return request.eventLoop.future(response)
    }
}
