//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct CircleRoleResponse: Content {
    var key: String
    var priority: Int
    var isDefault: Bool

    init(from role: CircleRole) throws {
        self.key = role.rawValue
        self.priority = role.priority
        self.isDefault = CircleRole.default == role
    }
}
