//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Foundation
import Vapor

internal struct CircleMemberNew: Content {
    var id: UUIDv4?
    var userId: UUIDv4
    var role: CircleRole?
}
