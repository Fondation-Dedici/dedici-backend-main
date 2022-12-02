//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import FCM
import Foundation
import Vapor

internal struct FcmConfiguration: AppConfiguration {
    func configure(_ application: Application) throws {
        application.fcm.configuration = .envServiceAccountKey
    }
}
