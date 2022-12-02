//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Fluent
import Foundation

internal struct MemberDeletionMiddleware: ModelMiddleware {
    typealias Model = CircleMember

    init() {}

    func delete(model: CircleMember, force: Bool, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        next.delete(model, force: force, on: db)
            .flatMap { CirclesRepository(database: db).promoteOlderMemberIfNeeded(in: model.circleId) }
    }
}
