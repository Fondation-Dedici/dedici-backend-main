//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import FCM
import Foundation
import Vapor

internal protocol Notification {
    static var type: UInt8 { get }

    var topic: String { get }
    var fcmNotification: FCMNotification? { get }
    var data: [String: String]? { get }
    var name: String? { get }
    var android: FCMAndroidConfig? { get }
    var webpush: FCMWebpushConfig? { get }
    var apns: FCMApnsConfig<FCMApnsPayload>? { get }

    static func make(
        from payload: JsonValue?,
        and authResult: ForwardedAuthResult,
        considering request: Request
    ) throws -> EventLoopFuture<[Notification]>
}

extension Notification {
    var fcmNotification: FCMNotification? { nil }
    var data: [String: String]? { nil }
    var name: String? { nil }
    var android: FCMAndroidConfig? { nil }
    var webpush: FCMWebpushConfig? { nil }
    var apns: FCMApnsConfig<FCMApnsPayload>? { nil }

    static func topicForUser(withId id: UUID) -> String {
        "user_\(id.uuidString.uppercased())"
    }

    static func topicForIdentity(withId id: UUID) -> String {
        "identity_\(id.uuidString.uppercased())"
    }
}
