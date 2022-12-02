//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

public struct PublicConfiguration: Codable {
    public static let current: PublicConfiguration = {
        do {
            let invitationMaximumMaxAge = try Environment.require(
                key: "INVITATION_MAX_MAX_AGE",
                using: Int.init
            )
            let invitationDefaultMaxAge = try Environment.require(
                key: "INVITATION_DEFAULT_MAX_AGE",
                using: Int.init
            )

            return PublicConfiguration(
                invitationMaximumMaxAge: invitationMaximumMaxAge,
                invitationDefaultMaxAge: invitationDefaultMaxAge
            )

        } catch {
            fatalError("Failed to load configuration because: \(error)")
        }
    }()

    public let invitationMaximumMaxAge: Int
    public let invitationDefaultMaxAge: Int
}
