//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent
import Foundation

internal struct ItemTicketsMiddleware: ModelMiddleware {
    typealias Model = CircleItem

    init() {}

    func create(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        next.create(model, on: db)
            .flatMapThrowing { try CircleItemTicketsRepository(database: db).updateTickets(for: model) }
            .flatMap { $0 }
    }

    func update(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        next.update(model, on: db)
            .flatMapThrowing { try CircleItemTicketsRepository(database: db).updateTickets(for: model) }
            .flatMap { $0 }
    }
}
