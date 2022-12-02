//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal struct CircleMembersController: ResourceController {
    typealias Resource = CircleMember

    func createNewMember(from request: Request) throws -> EventLoopFuture<CircleMemberResponse> {
        try extractThisMember(from: request)
            .flatMapThrowing { thisMember in
                let body = try request.content.decode(CircleMemberNew.self)
                let authResult: ForwardedAuthResult = try request.auth.require()
                let isTargetSubAccount = authResult.subaccounts.contains(body.userId)

                guard thisMember.role.canAddNewMembersDirectly || isTargetSubAccount else { throw Abort(.forbidden) }
                let role = body.role ?? .default
                guard thisMember.role.canCreateUser(with: role) else {
                    throw Abort(.forbidden, reason: "Role is too high.")
                }

                return CircleMember(
                    id: body.id?.value,
                    userId: body.userId.value,
                    circleId: thisMember.circleId,
                    role: role
                )
            }
            .flatMap {
                CircleMembersRepository(database: request.db).saving($0)
            }
            .flatMapThrowing { try CircleMemberResponse(from: $0, and: request) }
    }

    func readList(from request: Request) throws -> EventLoopFuture<[CircleMemberResponse]> {
        try defaultReadList(resourcesProvider: listMembers)(request)
    }

    private func listMembers(from request: Request) throws -> EventLoopFuture<[CircleMember]?> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        let members = request.repositories.get(for: CircleMembersRepository.self)
        return members.membersOfCircles(of: authResult.userId.value).map { $0 }
    }

    private func extractThisMember(
        from request: Request
    ) throws -> EventLoopFuture<CircleMember> {
        let authResult: ForwardedAuthResult = try request.auth.require()

        guard let circleId: UUIDv4 = request.parameters.get("circleId") else {
            throw Abort(.badRequest, reason: "Invalid or missing circle ID")
        }

        let members = request.repositories.get(for: CircleMembersRepository.self)
        let thisMember = members.find(authResult.userId.value, in: circleId.value)

        return thisMember.unwrap(or: Abort(.forbidden))
    }

    private func extractTargetedMember(
        from request: Request
    ) throws -> EventLoopFuture<CircleMember> {
        guard let circleId: UUIDv4 = request.parameters.get("circleId") else {
            throw Abort(.badRequest, reason: "Invalid or missing circle ID")
        }
        guard let userId: UUIDv4 = request.parameters.get("userId") else {
            throw Abort(.badRequest, reason: "Invalid or missing user ID")
        }

        let members = request.repositories.get(for: CircleMembersRepository.self)
        let targetedMember = members.find(userId.value, in: circleId.value)

        return targetedMember.unwrap(or: Abort(.notFound))
    }

    private func extractMembers(
        from request: Request
    ) throws -> EventLoopFuture<(thisMember: CircleMember, targetedMember: CircleMember)> {
        try extractThisMember(from: request).and(try extractTargetedMember(from: request))
            .map { ($0, $1) }
    }

    func updateMemberRole(from request: Request) throws -> EventLoopFuture<CircleMemberResponse> {
        let roleUpdate = try request.content.decode(CircleMemberRoleUpdate.self)

        return try extractMembers(from: request)
            .flatMapThrowing { thisMember, targetedMember -> CircleMember in
                let newRole = roleUpdate.newRole
                guard thisMember.role.canChangeUserRole(from: targetedMember.role, to: newRole) else {
                    throw Abort(.forbidden)
                }
                targetedMember.role = newRole
                return targetedMember
            }
            .flatMap { CircleMembersRepository(database: request.db).saving($0) }
            .flatMapThrowing { try CircleMemberResponse(from: $0, and: request) }
    }

    func kickMember(from request: Request) throws -> EventLoopFuture<Response> {
        try extractMembers(from: request)
            .flatMap { thisMember, targetedMember -> EventLoopFuture<Response> in
                guard
                    targetedMember.userId == thisMember.userId
                    || thisMember.role.canKickUser(with: targetedMember.role)
                else {
                    return request.eventLoop.makeFailedFuture(Abort(.forbidden))
                }
                let members = request.repositories.get(for: CircleMembersRepository.self)
                return members.delete(targetedMember)
                    .map { .init(status: .noContent) }
            }
    }
}
