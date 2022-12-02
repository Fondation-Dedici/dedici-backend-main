//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import Fluent
import Foundation
import Vapor

internal typealias CircleItemsRepository = DefaultRepository<CircleItem>

extension CircleItemsRepository {
    /// Returns the list of items that the identity can send
    func availableItems(
        on identityId: Identity.IDValue?,
        from database: Database? = nil
    ) -> EventLoopFuture<Set<CircleItem.IDValue>> {
        let database = database ?? self.database
        guard let identityId = identityId else {
            return database.eventLoop.makeSucceededFuture([])
        }

        return QueryBuilder<CircleItemTicket>(database: database)
            .filter(\.$identityId == identityId)
            .filter(\.$sharingConfirmationDate != nil)
            .all(\.$itemId)
            .map(Set.init)
    }

    /// Returns the list of items that in a circle
    func nonDeletedItems(
        for circleId: Circle.IDValue,
        from database: Database? = nil
    ) -> EventLoopFuture<[CircleItem]> {
        let database = database ?? self.database

        return QueryBuilder<CircleItem>(database: database)
            .filter(\.$circleId == circleId)
            .group(.or) { $0.filter(\.$deletionDate == nil).filter(\.$deletionDate > Date()) }
            .all()
    }

    /// Returns the list of items that in a circle
    func itemIds(
        for circleId: Circle.IDValue,
        from database: Database? = nil
    ) -> EventLoopFuture<[CircleItem.IDValue]> {
        let database = database ?? self.database

        return QueryBuilder<CircleItem>(database: database)
            .filter(\.$circleId == circleId)
            .all(\.$id)
    }

    /// Returns the list of items that the identity should have
    func items(
        for identity: Identity,
        from database: Database? = nil
    ) -> EventLoopFuture<[CircleItem]> {
        let database = database ?? self.database
        let circles = CirclesRepository(database: database).circles(for: identity.ownerId)

        return circles.flatMap { (circles: [Circle]) -> EventLoopFuture<[CircleItem]> in
            let ids = circles.compactMap(\.id)
            return QueryBuilder<CircleItem>(database: database)
                .filter(\.$circleId ~~ ids)
                .all()
        }
    }

    /// Returns the list of item ids that the identity should have
    func nonDeletedItemIds(
        for identity: Identity,
        from database: Database? = nil
    ) -> EventLoopFuture<Set<CircleItem.IDValue>> {
        let database = database ?? self.database
        let circles = CirclesRepository(database: database).circles(for: identity.ownerId)

        return circles.flatMap { (circles: [Circle]) -> EventLoopFuture<Set<CircleItem.IDValue>> in
            let ids = circles.compactMap(\.id)
            return QueryBuilder<CircleItem>(database: database)
                .filter(\.$circleId ~~ ids)
                .group(.or) { $0.filter(\.$deletionDate == nil).filter(\.$deletionDate > Date()) }
                .all(\.$id)
                .map(Set.init)
        }
    }
}
