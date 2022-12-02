//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal typealias CircleItemTicketsRepository = DefaultRepository<CircleItemTicket>

extension CircleItemTicketsRepository {
    private typealias ItemTicketsFactory<S: Sequence>
        = (_ identityIds: S) throws -> [CircleItemTicket] where S.Element == Identity.IDValue
    private typealias IdentityTicketsFactory<S: Sequence>
        = (_ items: S) throws -> [CircleItemTicket] where S.Element == CircleItem

    func removeExpiredAssignments(from database: Database? = nil) -> EventLoopFuture<Void> {
        let database = database ?? self.database

        return CircleItemTicket.query(on: database)
            .group(.and) { $0.filter(\.$assignmentExpirationDate != nil).filter(\.$assignmentExpirationDate <= Date()) }
            .all()
            .map { (tickets: [CircleItemTicket]) -> [CircleItemTicket] in
                tickets.forEach { ticket in
                    ticket.assigneeId = nil
                    ticket.assignmentExpirationDate = nil
                }
                return tickets
            }
            .flatMap { self.save($0, on: database) }
    }

    func tickets(for item: CircleItem, from database: Database? = nil) throws -> EventLoopFuture<[CircleItemTicket]> {
        let database = database ?? self.database
        guard let itemId = try? item.id.require() else {
            return database.eventLoop.makeSucceededFuture([])
        }

        return CircleItemTicket.query(on: database).filter(\.$itemId == itemId).all()
    }

    func confirmSharing(
        for itemId: CircleItem.IDValue,
        at versionTag: UUIDv4,
        to identityId: Identity.IDValue,
        from database: Database? = nil
    ) -> EventLoopFuture<CircleItemTicket?> {
        let database = database ?? self.database

        return CircleItemTicket.query(on: database)
            .filter(\.$identityId == identityId)
            .filter(\.$itemId == itemId)
            .filter(\.$versionTag == versionTag.value)
            .filter(\.$sharingConfirmationDate == nil)
            .first()
            .optionalFlatMap { (ticket: CircleItemTicket) -> EventLoopFuture<CircleItemTicket> in
                ticket.assigneeId = nil
                ticket.assignmentExpirationDate = nil
                ticket.sharingConfirmationDate = .init()

                return self.saving(ticket)
            }
    }

    func deleteTickets(
        for identityId: Identity.IDValue?,
        from database: Database? = nil
    ) -> EventLoopFuture<Void> {
        let database = database ?? self.database
        guard let identityId = identityId else {
            return database.eventLoop.makeSucceededFuture(())
        }

        return QueryBuilder<CircleItemTicket>(database: database)
            .filter(\.$identityId == identityId)
            .delete()
    }

    /// Returns the tickets that the identity should or will have
    func tickets(
        for identityId: Identity.IDValue?,
        from database: Database? = nil
    ) -> EventLoopFuture<[CircleItemTicket]> {
        let database = database ?? self.database
        guard let identityId = identityId else {
            return database.eventLoop.makeSucceededFuture([])
        }

        return QueryBuilder<CircleItemTicket>(database: database)
            .filter(\.$identityId == identityId)
            .all()
    }

    /// Returns the tickets that the identity should be able to handle
    private func unassignedTickets(
        for identityId: Identity.IDValue?,
        from database: Database? = nil
    ) -> EventLoopFuture<[CircleItemTicket]> {
        let database = database ?? self.database
        guard let identityId = identityId else {
            return database.eventLoop.makeSucceededFuture([])
        }

        let itemsRepository = CircleItemsRepository(database: database)
        let availableItems = itemsRepository.availableItems(on: identityId)

        return availableItems
            .flatMap { itemIds in
                QueryBuilder<CircleItemTicket>(database: database)
                    .filter(\.$itemId ~~ itemIds)
                    .filter(\.$sharingConfirmationDate == nil)
                    .filter(\.$assigneeId == nil)
                    .filter(\.$identityId != identityId)
                    .all()
            }
    }

    /// Returns the tickets that the identity should be able to handle after assigning them
    func assigningTickets(
        for identityId: Identity.IDValue?,
        maximumCount: UInt32,
        expirationDate: Date,
        from database: Database? = nil
    ) -> EventLoopFuture<[CircleItemTicket]> {
        let database = (database ?? self.database)
        return database.transaction { database in
            self.unassignedTickets(for: identityId, from: database)
                .map { tickets in
                    tickets
                        .prefix(Int(max(maximumCount, 0)))
                        .map { ticket in
                            ticket.assigneeId = identityId
                            ticket.assignmentExpirationDate = expirationDate
                            return ticket
                        }
                }
                .flatMap { self.saving($0, on: database) }
        }
    }

    func updateTickets(for member: CircleMember, on database: Database? = nil) throws -> EventLoopFuture<Void> {
        (database ?? self.database).transaction { database -> EventLoopFuture<Void> in
            let identitiesRepository = IdentitiesRepository(database: database)
            let itemsRepository = CircleItemsRepository(database: database)

            let items = itemsRepository.nonDeletedItems(for: member.circleId)
            let identityIds = identitiesRepository.identityIdsOfUser(withId: member.userId)

            return items.and(identityIds)
                .flatMap { (items: [CircleItem], identityIds: [Identity.IDValue]) -> EventLoopFuture<Void> in
                    let itemIds = Set(items.compactMap(\.id))
                    let existingTickets = QueryBuilder<CircleItemTicket>(database: database)
                        .filter(\.$identityId ~~ identityIds)
                        .filter(\.$itemId ~~ itemIds)
                        .all()

                    return existingTickets.flatMapThrowing { (tickets: [CircleItemTicket]) -> [CircleItemTicket] in
                        guard tickets.count < (itemIds.count * identityIds.count) else { return [] }
                        typealias Tickets = [String: CircleItemTicket]
                        let ticketIdFromTicket: (CircleItemTicket) -> String = { "\($0.itemId)-\($0.identityId)" }
                        let ticketId: (CircleItem.IDValue, Identity.IDValue) -> String = { "\($0)-\($1)" }

                        let existingTickets = tickets.reduce(into: Tickets()) { $0[ticketIdFromTicket($1)] = $1 }

                        var newTickets = Tickets()
                        for identityId in identityIds {
                            for item in items {
                                let itemId = try item.id.require()
                                let id = ticketId(itemId, identityId)
                                if existingTickets[id] == nil {
                                    newTickets[id] = CircleItemTicket(
                                        itemId: try .init(value: itemId),
                                        identityId: try .init(value: identityId),
                                        versionTag: try .init(value: item.versionTag)
                                    )
                                }
                            }
                        }
                        return newTickets.values.map { $0 }
                    }
                    .flatMap { self.save($0, on: database) }
                }
        }
    }

    func updateTickets(for identity: Identity, on database: Database? = nil) throws -> EventLoopFuture<Void> {
        let identityId = try identity.id.require()
        let factory: IdentityTicketsFactory<[CircleItem]> = ticketsFactory(identityId: identityId)

        return (database ?? self.database).transaction { database -> EventLoopFuture<Void> in
            let itemsRepository = CircleItemsRepository(database: database)
            let itemIds = itemsRepository.nonDeletedItemIds(for: identity)

            return QueryBuilder<CircleItemTicket>(database: database)
                .filter(\.$identityId == identityId)
                .all(\.$itemId)
                .map(Set.init)
                .and(itemIds)
                .map { $1.subtracting($0) }
                .flatMap { itemsRepository.find($0).unwrap(or: Abort(.internalServerError)) }
                .flatMapThrowing(factory)
                .flatMap { self.save($0, on: database) }
        }
    }

    func updateTickets(for item: CircleItem, on database: Database? = nil) throws -> EventLoopFuture<Void> {
        let itemId = try item.id.require()
        let database = (database ?? self.database)
        guard !item.hasBeenDeleted else {
            return try tickets(for: item, from: database).flatMap { self.delete($0, on: database) }
        }

        let factory: ItemTicketsFactory<Set<UUID>> = ticketsFactory(item: item)

        return database.transaction { database -> EventLoopFuture<Void> in
            let identitiesRepository = IdentitiesRepository(database: database)
            let identityIds = identitiesRepository.identityIds(for: item.circleId).map(Set.init)

            let createNewTickets = QueryBuilder<CircleItemTicket>(database: database)
                .filter(\.$itemId == itemId)
                .filter(\.$versionTag == item.versionTag)
                .all(\.$identityId)
                .map(Set.init)
                .and(identityIds)
                .map { $1.subtracting($0) }
                .flatMapThrowing(factory)
                .flatMap { self.save($0, on: database) }
            let deleteOutdatedTickets = QueryBuilder<CircleItemTicket>(database: database)
                .filter(\.$itemId == itemId)
                .filter(\.$versionTag != item.versionTag)
                .delete()

            return deleteOutdatedTickets
                .flatMap { createNewTickets }
        }
    }

    private func ticketsFactory<S>(item: CircleItem) -> ItemTicketsFactory<S> {
        {
            try $0.map {
                .init(
                    itemId: try .init(value: item.id.require()),
                    identityId: try .init(value: $0),
                    versionTag: try .init(value: item.versionTag),
                    sharingConfirmationDate: $0 == item.versionIssuerIdentityId ? Date() : nil
                )
            }
        }
    }

    private func ticketsFactory<S>(identityId: Identity.IDValue) -> IdentityTicketsFactory<S> {
        {
            try $0.map {
                .init(
                    itemId: try .init(value: $0.id.require()),
                    identityId: try .init(value: identityId),
                    versionTag: try .init(value: $0.versionTag)
                )
            }
        }
    }
}
