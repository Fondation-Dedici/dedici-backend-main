//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import Fluent
import Foundation
import Vapor

internal typealias IdentitiesRepository = DefaultRepository<Identity>

extension IdentitiesRepository {
    func identityIdsOfUser(
        withId userId: UUID?,
        from database: Database? = nil
    ) -> EventLoopFuture<[Identity.IDValue]> {
        let database = database ?? self.database
        guard let userId = userId else {
            return database.eventLoop.makeSucceededFuture([])
        }

        return Identity.query(on: database).filter(\.$ownerId == userId).all(\.$id)
    }

    func identitiesOfUser(for userId: UUID?, from database: Database? = nil) -> EventLoopFuture<[Identity]> {
        let database = database ?? self.database
        guard let userId = userId else {
            return database.eventLoop.makeSucceededFuture([])
        }

        return Identity.query(on: database).filter(\.$ownerId == userId).all()
    }

    func identityIds(for circleId: Circle.IDValue?, from database: Database? = nil) -> EventLoopFuture<[UUID]> {
        let database = database ?? self.database
        guard let circleId = circleId else {
            return database.eventLoop.makeSucceededFuture([])
        }

        return DefaultRepository<CircleMember>(database: database)
            .memberIds(of: circleId)
            .flatMap { Identity.query(on: database).filter(\.$ownerId ~~ $0).all(\.$id) }
    }
}
