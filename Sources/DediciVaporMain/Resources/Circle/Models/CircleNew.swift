//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct CircleNew: Codable, ResourceCreateOneRequestBody {
    typealias Resource = Circle

    var id: UUIDv4?
    var publicContent: JsonObject?

    func asResource(considering request: Request) throws -> EventLoopFuture<Resource> {
        request.eventLoop.makeSucceededFuture(try asResource(considering: request))
    }

    func asResource(considering request: Request) throws -> Resource {
        let body = try request.content.decode(Self.self)
        let jsonEncoder = ContentConfiguration.jsonEncoder
        let circle = try Circle(
            id: body.id?.value ?? .init(),
            publicContent: body.publicContent.flatMap(jsonEncoder.encode)
        )

        return circle
    }
}
