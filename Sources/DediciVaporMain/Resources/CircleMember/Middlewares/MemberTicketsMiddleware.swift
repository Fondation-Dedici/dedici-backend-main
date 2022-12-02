//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent
import Foundation

internal struct MemberTicketsMiddleware: ModelMiddleware {
    typealias Model = CircleMember

    init() {}

    func create(model: Model, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        next.create(model, on: db)
            .flatMapThrowing { try CircleItemTicketsRepository(database: db).updateTickets(for: model, on: db) }
            .flatMap { $0 }
    }
}
