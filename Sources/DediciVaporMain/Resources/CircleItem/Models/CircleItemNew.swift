//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct CircleItemNew: Codable, ResourceCreateOneRequestBody {
    typealias Resource = CircleItem

    var id: UUIDv4?
    var versionTag: UUIDv4?
    var isGroupItem: Bool

    func asResource(considering request: Request) throws -> EventLoopFuture<Resource> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        let body = try request.content.decode(Self.self)
        guard let circleId: UUIDv4 = request.parameters.get("circleId") else {
            throw Abort(.badRequest, reason: "Invalid or missing circle ID")
        }
        let item = CircleItem(
            id: body.id?.value,
            ownerId: body.isGroupItem ? nil : authResult.userId,
            circleId: circleId,
            versionTag: body.versionTag ?? .init(),
            versionIssuerIdentityId: authResult.identityId
        )

        return request.eventLoop.makeSucceededFuture(item)
    }
}
