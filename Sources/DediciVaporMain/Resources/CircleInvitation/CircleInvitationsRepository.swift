//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal typealias CircleInvitationsRepository = DefaultRepository<CircleInvitation>

extension CircleInvitationsRepository {
    func allInvitations(
        for userId: UUID,
        orFor circleIds: [UUID],
        from database: Database? = nil
    ) -> EventLoopFuture<[CircleInvitation]> {
        CircleInvitation.query(on: database ?? self.database)
            .group(.or) { group in
                group
                    .filter(\.$issuerUserId == userId)
                    .filter(\.$circleId ~~ circleIds)
            }
            .all()
    }

    func findPendingInvitation(for code: String, on database: Database? = nil) -> EventLoopFuture<CircleInvitation> {
        let database = database ?? self.database
        return CircleInvitation.query(on: database)
            .filter(\.$activationCode == code)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { invitation -> CircleInvitation in
                guard !invitation.hasExpired else { throw Abort(.badRequest, reason: "The invitation has expired.") }
                guard !invitation.hasAlreadyBeenActivated else {
                    throw Abort(.badRequest, reason: "The invitation has already been activated.")
                }

                guard invitation.activationCode == code else { throw Abort(.notFound) }

                return invitation
            }
    }

    func publicContent(for code: String, on database: Database? = nil) -> EventLoopFuture<JsonObject?> {
        let database = database ?? self.database
        return findPendingInvitation(for: code)
            .flatMap { invitation -> EventLoopFuture<JsonObject?> in
                CirclesRepository(database: database)
                    .find(invitation.circleId)
                    .unwrap(or: Abort(
                        .internalServerError,
                        reason: "Invalid circle id \(invitation.circleId) "
                            + "in invitation: \(invitation.id?.uuidString ?? "")"
                    ))
                    .map(\.publicContent)
                    .optionalFlatMapThrowing { (publicContent: Data) throws -> JsonObject in
                        let decoder = ContentConfiguration.jsonDecoder
                        return try decoder.decode(JsonObject.self, from: publicContent)
                    }
            }
    }

    func activate(
        _ code: String,
        for identityId: Identity.IDValue,
        and userId: Identity.IDValue,
        on database: Database? = nil
    ) -> EventLoopFuture<CircleInvitation> {
        let database = database ?? self.database
        return findPendingInvitation(for: code)
            .flatMap { invitation -> EventLoopFuture<CircleInvitation> in
                CircleMembersRepository(database: database)
                    .find(userId, in: invitation.circleId)
                    .flatMapThrowing { member -> CircleInvitation in
                        guard member == nil else {
                            throw Abort(.forbidden, reason: "User is already part of that circle.")
                        }
                        return invitation
                    }
            }
            .flatMapThrowing { invitation -> CircleInvitation in
                guard invitation.issuerUserId != userId else { throw Abort(.forbidden) }
                guard invitation.issuerIdentityId != identityId else { throw Abort(.forbidden) }

                try invitation.activate(for: identityId, and: userId)

                return invitation
            }
            .flatMap { self.saving($0) }
    }
}
