//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal struct CircleInvitationsController: ResourceController {
    typealias Resource = CircleInvitation

    func createOne(from request: Request) throws -> EventLoopFuture<CircleInvitationResponse> {
        try defaultCreateOne(resourceValidator: .init(checkCreationPermission))(request)
    }

    func readList(from request: Request) throws -> EventLoopFuture<[CircleInvitationResponse]> {
        try defaultReadList(resourcesProvider: userRelatedInvitations)(request)
    }

    private func userRelatedInvitations(request: Request) throws -> EventLoopFuture<[CircleInvitation]?> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        let members = CircleMembersRepository(database: request.db)
        let circles = CirclesRepository(database: request.db)
        let invitations = CircleInvitationsRepository(database: request.db)
        return members.membersForUser(authResult.userId.value)
            .flatMap { (members: [CircleMember]) -> EventLoopFuture<[Circle.IDValue]?> in
                circles
                    .find(members.filter(\.role.canSeeInvitations).map(\.circleId))
                    .map { ($0 ?? []).compactMap(\.id) }
            }
            .flatMap { (circleIds: [Circle.IDValue]?) -> EventLoopFuture<[CircleInvitation]?> in
                invitations.allInvitations(for: authResult.userId.value, orFor: circleIds ?? []).map { $0 }
            }
    }

    func forceExpireInvitation(for request: Request) throws -> EventLoopFuture<CircleInvitationResponse> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        guard let invitationId: UUIDv4 = request.parameters.get("invitationId") else { throw Abort(.badRequest) }

        return request.db.transaction { database -> EventLoopFuture<CircleInvitationResponse> in
            let invitations = CircleInvitationsRepository(database: database)
            return invitations.find(invitationId.value)
                .unwrap(or: Abort(.notFound))
                .flatMap { (invitation: CircleInvitation) -> EventLoopFuture<CircleInvitation> in
                    let members = CircleMembersRepository(database: database)
                    return members.role(of: authResult.userId.value, in: invitation.circleId)
                        .flatMapThrowing { role in
                            guard let role = role, role.canForceExpireInvitations else { throw Abort(.forbidden) }
                            return invitation
                        }
                }
                .flatMap { invitations.markingAsExpired($0) }
                .flatMapThrowing { try CircleInvitationResponse(from: $0, and: request) }
        }
    }

    func publicContent(for request: Request) throws -> EventLoopFuture<JsonObject> {
        let activationCode: String = try request.query.get(at: "code")

        return CircleInvitationsRepository(database: request.db)
            .publicContent(for: activationCode)
            .unwrap(or: Abort(.notFound))
    }

    func activateInvitation(for request: Request) throws -> EventLoopFuture<CircleInvitationResponse> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        let body = try request.content.decode(CircleInvitationActivation.self)

        return request.db.transaction { (database: Database) -> EventLoopFuture<CircleInvitationResponse> in
            request.repositories.get(for: CircleInvitationsRepository.self)
                .activate(body.activationCode, for: authResult.identityId.value, and: authResult.userId.value)
                .flatMapThrowing { invitation in
                    (CircleMember(
                        userId: authResult.userId.value,
                        circleId: invitation.circleId,
                        role: .default
                    ), invitation)
                }
                .flatMap { values -> EventLoopFuture<CircleInvitation> in
                    CircleMembersRepository(database: database).saving(values.0).map { _ in values.1 }
                }
                .flatMapThrowing { try CircleInvitationResponse(from: $0, and: request) }
        }
    }

    private func checkCreationPermission(
        for invitation: CircleInvitation,
        considering request: Request
    ) throws -> EventLoopFuture<Void> {
        let members = request.repositories.get(for: CircleMembersRepository.self)
        return members.role(of: invitation.issuerUserId, in: invitation.circleId)
            .flatMapThrowing { role in
                guard let role = role, role.canInviteNewMembers else { throw Abort(.forbidden) }
            }
    }
}
