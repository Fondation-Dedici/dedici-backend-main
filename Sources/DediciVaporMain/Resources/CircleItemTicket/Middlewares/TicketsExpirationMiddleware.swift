//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

internal struct TicketsExpirationMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        CircleItemTicketsRepository(database: request.db)
            .removeExpiredAssignments()
            .flatMap { next.respond(to: request) }
    }
}
