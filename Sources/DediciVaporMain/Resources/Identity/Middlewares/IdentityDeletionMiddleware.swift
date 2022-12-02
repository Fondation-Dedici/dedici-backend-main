//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent
import Foundation

internal struct IdentityDeletionMiddleware: ModelMiddleware {
    typealias Model = Identity

    init() {}

    func delete(model: Identity, force: Bool, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        next.delete(model, force: force, on: db)
            .flatMap { CircleItemTicketsRepository(database: db).deleteTickets(for: model.id) }
    }
}
