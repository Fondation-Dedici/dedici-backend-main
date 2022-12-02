//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal struct ModelMiddlewaresConfiguration: AppConfiguration {
    func configure(_ application: Application) throws {
        let middlewares: [AnyModelMiddleware] = [
            ResourceModelMiddleware<Circle>(),
            ResourceModelMiddleware<CircleMember>(),
            ResourceModelMiddleware<CircleItem>(),
            ResourceModelMiddleware<CircleItemTicket>(),
            ResourceModelMiddleware<Identity>(),
            ResourceModelMiddleware<CircleInvitation>(),
            IdentityDeletionMiddleware(),
            IdentityHopperMiddleware(),
            ItemTicketsMiddleware(),
            MemberTicketsMiddleware(),
            MemberDeletionMiddleware(),
        ]

        middlewares.forEach { application.databases.middleware.use($0) }
    }
}
