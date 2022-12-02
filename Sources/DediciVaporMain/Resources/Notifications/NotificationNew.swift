//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Foundation
import Vapor

internal struct NotificationNew: Content {
    let payload: JsonValue?
    let type: UInt8
}
