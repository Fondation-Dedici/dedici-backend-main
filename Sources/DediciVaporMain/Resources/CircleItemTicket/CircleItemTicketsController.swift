//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal struct CircleItemTicketsController: ResourceController {
    typealias Resource = CircleItemTicket

    func selfAssign(from request: Request) throws -> EventLoopFuture<[CircleItemTicketResponse]> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        let body = try request.content.decode(CircleItemTicketAssignment.self)
        let repository = CircleItemTicketsRepository(database: request.db)

        let maxTickets = max(min(body.maxTickets ?? 50, 50), 0)
        let defaultAge: Double = 60 * 60 * 24
        let maxAge = max(min(body.maxAge ?? defaultAge, defaultAge), 10)

        return repository
            .assigningTickets(
                for: authResult.identityId.value,
                maximumCount: maxTickets,
                expirationDate: Date().addingTimeInterval(maxAge)
            )
            .flatMapThrowing { try $0.map { try CircleItemTicketResponse(from: $0, and: request) } }
    }

    func confirmSharing(from request: Request) throws -> EventLoopFuture<Response> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        let body = try request.content.decode([CircleItemTicketConfirmation].self)
        let repository = CircleItemTicketsRepository(database: request.db)

        let operations = body.map {
            repository
                .confirmSharing(for: $0.itemId.value, at: $0.versionTag, to: authResult.identityId.value)
                .map { _ in }
        }
        return EventLoopFuture<Void>.andAllSucceed(operations, on: request.eventLoop)
            .map { .init(status: .noContent) }
    }

    func readList(from request: Request) throws -> EventLoopFuture<[CircleItemTicketResponse]> {
        try defaultReadList(resourcesProvider: identityRelatedTickets)(request)
    }

    private func identityRelatedTickets(request: Request) throws -> EventLoopFuture<[CircleItemTicket]?> {
        let authResult: ForwardedAuthResult = try request.auth.require()
        let tickets = CircleItemTicketsRepository(database: request.db)

        return tickets.tickets(for: authResult.identityId.value).map { $0 }
    }
}
