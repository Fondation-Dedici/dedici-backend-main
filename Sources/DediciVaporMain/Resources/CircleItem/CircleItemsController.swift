//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal struct CircleItemsController: ResourceController {
    typealias Resource = CircleItem

    func markAsDeleted(from request: Request) throws -> EventLoopFuture<CircleItemResponse> {
        try defaultMarkAsDeletedOne(
            idPathComponentName: "itemId",
            resourceValidator: .init(checkItemDeletePermission)
        )(request)
    }

    func updateVersion(from request: Request) throws -> EventLoopFuture<CircleItemResponse> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        guard let itemId: UUIDv4 = request.parameters.get("itemId") else {
            throw Abort(.badRequest)
        }
        let body = try request.content.decode(CircleItemVersionUpdate.self)
        let repository = CircleItemsRepository(database: request.db)

        return repository
            .find(itemId.value)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { item in
                try self.checkItemWritePermission(for: item, considering: request)
                    .map { item }
            }
            .flatMap { $0 }
            .flatMapThrowing {
                let newTag = body.newVersionTag?.value ?? .init()
                guard newTag != $0.versionTag else { return request.eventLoop.makeSucceededFuture($0) }

                $0.versionTag = newTag
                $0.versionIssuerIdentityId = authResult.identityId.value

                return repository.saving($0)
            }
            .flatMap { $0 }
            .flatMapThrowing { try CircleItemResponse(from: $0, and: request) }
    }

    func createOne(from request: Request) throws -> EventLoopFuture<CircleItemResponse> {
        try defaultCreateOne(resourceValidator: .init(checkItemWritePermission))(request)
    }

    private func checkItemWritePermission(
        for item: CircleItem,
        considering request: Request
    ) throws -> EventLoopFuture<Void> {
        guard !item.hasBeenDeleted else {
            throw Abort(.notFound)
        }

        return try checkItemDeletePermission(for: item, considering: request)
    }

    private func checkItemDeletePermission(
        for item: CircleItem,
        considering request: Request
    ) throws -> EventLoopFuture<Void> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        if let ownerId = item.ownerId {
            guard authResult.userId.value == ownerId else {
                throw Abort(.forbidden)
            }
            return request.eventLoop.future()
        }

        let members = CircleMembersRepository(database: request.db)

        let role = members.role(of: authResult.userId.value, in: item.circleId)

        return role
            .unwrap(or: Abort(.forbidden))
            .flatMapThrowing {
                guard $0.canWriteGroupOwnedItems else { throw Abort(.forbidden) }
            }
    }

    func readList(from request: Request) throws -> EventLoopFuture<[CircleItemResponse]> {
        try defaultReadList(resourcesProvider: userRelatedItems)(request)
    }

    private func userRelatedItems(request: Request) throws -> EventLoopFuture<[CircleItem]?> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        let identities = IdentitiesRepository(database: request.db)
        let items = CircleItemsRepository(database: request.db)

        return identities.find(authResult.identityId.value)
            .unwrap(or: Abort(.forbidden))
            .flatMap { items.items(for: $0) }
            .map { $0 }
    }
}
