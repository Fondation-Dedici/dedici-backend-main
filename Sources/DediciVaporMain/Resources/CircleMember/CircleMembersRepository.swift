//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal typealias CircleMembersRepository = DefaultRepository<CircleMember>

extension CircleMembersRepository {
    func find(
        _ userId: UUID,
        in circleId: Circle.IDValue,
        from database: Database? = nil
    ) -> EventLoopFuture<CircleMember?> {
        let database = database ?? self.database

        return CircleMember.query(on: database)
            .filter(\.$userId == userId)
            .filter(\.$circleId == circleId)
            .first()
    }

    func membersForUser(_ userId: UUID, from database: Database? = nil) -> EventLoopFuture<[CircleMember]> {
        let database = database ?? self.database
        return CircleMember.query(on: database)
            .filter(\.$userId == userId)
            .all()
    }

    func memberIds(of circleId: Circle.IDValue?, from database: Database? = nil) -> EventLoopFuture<[UUID]> {
        let database = database ?? self.database
        guard let circleId = circleId else {
            return database.eventLoop.makeSucceededFuture([])
        }

        return CircleMember.query(on: database).filter(\.$circleId == circleId).all(\.$userId)
    }

    func members(of circleId: Circle.IDValue?, from database: Database? = nil) -> EventLoopFuture<[CircleMember]> {
        let database = database ?? self.database
        guard let circleId = circleId else {
            return database.eventLoop.makeSucceededFuture([])
        }

        return CircleMember.query(on: database).filter(\.$circleId == circleId).all()
    }

    func membersOfCircles(of userId: UUID, from database: Database? = nil) -> EventLoopFuture<[CircleMember]> {
        let database = database ?? self.database
        return CirclesRepository(database: database).circles(for: userId).flatMap { circles in
            CircleMember.query(on: database).filter(\.$circleId ~~ circles.compactMap(\.id)).all()
        }
    }

    func role(
        of userId: UUID,
        in circleId: Circle.IDValue,
        from database: Database? = nil
    ) -> EventLoopFuture<CircleRole?> {
        CircleMember.query(on: database ?? self.database)
            .filter(\.$userId == userId)
            .filter(\.$circleId == circleId)
            .first()
            .map { $0?.role }
    }
}
