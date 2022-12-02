//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import Fluent
import Foundation
import Vapor

internal typealias CirclesRepository = DefaultRepository<Circle>

extension CirclesRepository {
    func commonCircles(between userIds: [UUID]) -> EventLoopFuture<Set<UUID>> {
        guard !userIds.isEmpty else { return database.eventLoop.makeSucceededFuture([]) }
        return CircleMember.query(on: database)
            .filter(\.$userId ~~ userIds)
            .all()
            .map { (members: [CircleMember]) -> Set<Circle.IDValue> in
                userIds
                    .reduce(into: [UUID: Set<Circle.IDValue>]()) { output, userId in
                        output[userId] = Set(members.filter { $0.userId == userId }.map(\.circleId))
                    }
                    .values
                    .reduce(nil) { $0?.intersection($1) ?? $1 } ?? []
            }
    }

    func promoteOlderMemberIfNeeded(
        in circleId: Circle.IDValue,
        on database: Database? = nil
    ) -> EventLoopFuture<Void> {
        let database = database ?? self.database
        let highestRoleMembersCount = CircleMember.query(on: database)
            .filter(\.$circleId == circleId)
            .filter(\.$role == .highest)
            .count()

        return highestRoleMembersCount
            .flatMap { (count: Int) -> EventLoopFuture<Void> in
                guard count < 1 else { return database.eventLoop.future() }

                return self.promoteOlderMember(in: circleId, on: database)
            }
    }

    private func promoteOlderMember(
        in circleId: Circle.IDValue,
        on database: Database? = nil
    ) -> EventLoopFuture<Void> {
        let database = database ?? self.database
        return CircleMember.query(on: database)
            .filter(\.$circleId == circleId)
            .sort(\.$creationDate, .ascending)
            .first()
            .flatMap { (member: CircleMember?) -> EventLoopFuture<Void> in
                guard let member = member else { return database.eventLoop.future() }
                member.role = .highest
                return CircleMembersRepository(database: database).save(member)
            }
    }

    func circles(for userId: UUID, from database: Database? = nil) -> EventLoopFuture<[Circle]> {
        let database = database ?? self.database
        return CircleMember.query(on: database)
            .filter(\.$userId == userId)
            .unique()
            .all(\.$circleId)
            .flatMap { Circle.query(on: database).filter(\.$id ~~ $0).all() }
    }
}
