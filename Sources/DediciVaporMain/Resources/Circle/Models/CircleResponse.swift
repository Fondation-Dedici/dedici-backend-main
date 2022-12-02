//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct CircleResponse: ResourceRequestResponse {
    var id: UUIDv4
    var creationDate: Date
    var lastModificationDate: Date
    var deletionDate: Date?
    var publicContent: JsonObject?

    init(from resource: Circle, and _: Request) throws {
        self.id = try .init(value: resource.id.require())
        self.creationDate = resource.creationDate
        self.deletionDate = resource.deletionDate
        self.lastModificationDate = resource.lastModificationDate
        let decoder = ContentConfiguration.jsonDecoder
        self.publicContent = try resource.publicContent.flatMap { try decoder.decode(JsonObject.self, from: $0) }
    }

    static func make(from resource: Circle, and request: Request) throws -> EventLoopFuture<Self> {
        let response = try Self(from: resource, and: request)
        return request.eventLoop.future(response)
    }
}
