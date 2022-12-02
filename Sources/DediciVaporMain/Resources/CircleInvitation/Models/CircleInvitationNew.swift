//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct CircleInvitationNew: Codable, ResourceCreateOneRequestBody, Validatable {
    typealias Resource = CircleInvitation

    static func validations(_ validations: inout Validations) {
        let invitationMaximumMaxAge = PublicConfiguration.current.invitationMaximumMaxAge
        validations.add("maxAge", as: Int.self, is: .range(0 ... invitationMaximumMaxAge), required: false)
    }

    var id: UUIDv4?
    var maxAge: Int?

    func asResource(considering request: Request) throws -> EventLoopFuture<Resource> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        let body = try request.content.decode(Self.self)
        guard let circleId: UUIDv4 = request.parameters.get("circleId") else {
            throw Abort(.badRequest, reason: "Invalid or missing circle ID")
        }
        let invitation = CircleInvitation(
            id: id?.value,
            issuerUserId: authResult.userId,
            issuerIdentityId: authResult.identityId,
            circleId: circleId,
            maxAge: body.maxAge ?? PublicConfiguration.current.invitationDefaultMaxAge
        )

        return request.eventLoop.makeSucceededFuture(invitation)
    }
}
