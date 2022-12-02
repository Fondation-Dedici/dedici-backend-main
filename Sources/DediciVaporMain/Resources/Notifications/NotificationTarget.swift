//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

internal enum NotificationTarget: String, Hashable, Codable {
    case android
    case ios
    case webpush

    func format(topic: String, environment: Environment) -> String {
        "\(environment.name)_\(rawValue)_\(topic)"
    }
}
