//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal struct CirclesController: RouteCollection, ResourceController {
    typealias Resource = Circle

    private let rolesController = CircleRolesController()
    private let membersController = CircleMembersController()
    private let itemsController = CircleItemsController()
    private let invitationsController = CircleInvitationsController()
    private let ticketsController = CircleItemTicketsController()

    func boot(routes: RoutesBuilder) throws {
        let circles = routes
            .grouped(ForwardedAuthAuthenticator(), ForwardedAuthResult.guardMiddleware())
            .grouped("circles")

        circles.post(use: createCircle)
        circles.get(use: readList)
        circles.get("members", use: membersController.readList)
        circles.group("invitations") {
            $0.group(":invitationId") {
                $0.patch("force-expire", use: invitationsController.forceExpireInvitation)
            }
            $0.patch("activate", use: invitationsController.activateInvitation)
            $0.get("public-content", use: invitationsController.publicContent)
            $0.get(use: invitationsController.readList)
        }
        circles.group("tickets") {
            $0.get(use: ticketsController.readList)
            $0.patch("confirm", use: ticketsController.confirmSharing)
            $0.patch("self-assign", use: ticketsController.selfAssign)
        }
        circles.group("items") {
            $0.get(use: itemsController.readList)
            $0.group(":itemId") {
                $0.patch("update-version", use: itemsController.updateVersion)
                $0.patch("mark-as-deleted", use: itemsController.markAsDeleted)
            }
        }
        circles.get("roles", use: rolesController.listAllRoles)
        circles.group(":circleId") {
            $0.post("invitations", use: invitationsController.createOne)
            $0.patch("mark-as-deleted", use: markAsDeletedOne)
            $0.patch("update-public-content", use: updatePublicContent)
            $0.group("members") {
                $0.group(":userId") {
                    $0.delete(use: membersController.kickMember)
                    $0.patch("update-role", use: membersController.updateMemberRole)
                }
                $0.post(use: membersController.createNewMember)
            }
            $0.group("items") {
                $0.post(use: itemsController.createOne)
            }
        }
    }

    func markAsDeletedOne(from request: Request) throws -> EventLoopFuture<CircleResponse> {
        try defaultMarkAsDeletedOne(
            idPathComponentName: "circleId",
            resourceValidator: .init(checkDeletionPermission)
        )(request)
    }

    func readList(for request: Request) throws -> EventLoopFuture<[CircleResponse]> {
        try defaultReadList(resourcesProvider: listCircles)(request)
    }

    func listCircles(for request: Request) throws -> EventLoopFuture<[Circle]?> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        return CirclesRepository(database: request.db).circles(for: authResult.userId.value).map { $0 }
    }

    func updatePublicContent(from request: Request) throws -> EventLoopFuture<CircleResponse> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        let body = try request.content.decode(CirclePublicContentUpdate.self)
        let circleId: UUIDv4 = try request.parameters.require("circleId")
        let repository = CirclesRepository(database: request.db)
        let circle = repository
            .find(circleId.value)
            .unwrap(or: Abort(.notFound))
        let role = CircleMembersRepository(database: request.db)
            .role(of: authResult.userId.value, in: circleId.value)
            .unwrap(or: Abort(.forbidden, reason: "User is not part of that circle."))

        return role.and(circle)
            .flatMapThrowing { (role: CircleRole, circle: Circle) -> Circle in
                guard role.canUpdatePublicContent else {
                    throw Abort(
                        .forbidden,
                        reason: "User role for this circle does not allow for public content update."
                    )
                }

                let encoder = ContentConfiguration.jsonEncoder
                circle.publicContent = try body.newPublicContent.flatMap(encoder.encode)
                return circle
            }
            .flatMap { repository.saving($0) }
            .flatMapThrowing { try CircleResponse.make(from: $0, and: request) }
            .flatMap { $0 }
    }

    func createCircle(from request: Request) throws -> EventLoopFuture<CircleResponse> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        let body = try Resource.DefaultCreateOneBody.extract(from: request)
        let circle: Circle = try body.asResource(considering: request)
        let circleId = circle.id ?? .init()
        let member = CircleMember(userId: authResult.userId.value, circleId: circleId, role: .administrator)

        return request.db.transaction { (database: Database) -> EventLoopFuture<CircleResponse> in
            let circles = CirclesRepository(database: database)
            let members = CircleMembersRepository(database: database)

            return members.create(member)
                .flatMap { circles.creating(circle) }
                .flatMapThrowing { try CircleResponse(from: $0, and: request) }
        }
    }

    private func checkDeletionPermission(
        for circle: Circle,
        considering request: Request
    ) throws -> EventLoopFuture<Void> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        let members = request.repositories.get(for: CircleMembersRepository.self)
        return members.role(of: authResult.userId.value, in: try circle.id.require())
            .flatMapThrowing { role in
                guard role?.canDeleteCircle == true else { throw Abort(.forbidden) }
            }
    }
}
