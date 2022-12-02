//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

internal struct CircleItemTicketAssignment: Content {
    let maxTickets: UInt32?
    let maxAge: Double?
}
