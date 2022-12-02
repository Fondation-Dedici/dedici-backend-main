//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Foundation
import Vapor

internal struct CircleRolesController {
    func listAllRoles(for request: Request) throws -> EventLoopFuture<[String: CircleRoleResponse]> {
        let roles = try CircleRole.allCases.reduce(into: [:]) { $0[$1.rawValue] = try CircleRoleResponse(from: $1) }
        return request.eventLoop.makeSucceededFuture(roles)
    }
}
