//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import FCM
import Fluent
import Foundation
import Vapor

internal struct NewMessageNotification: Notification {
    static let type: UInt8 = 0

    let topic: String
    let circleId: UUID

    var data: [String: String]? {
        ["circleId": circleId.uuidString]
    }

    static func make(
        from payload: JsonValue?,
        and authResult: ForwardedAuthResult,
        considering request: Request
    ) throws -> EventLoopFuture<[Notification]> {
        guard let payload = payload?.object else { throw Abort(.badRequest, reason: "Payload must be a JsonObject") }
        let recipientUserIdKey = "recipientUserId"
        guard let recipientUserIdString = payload[recipientUserIdKey]?.string else {
            throw Abort(.badRequest, reason: "Payload must contain a string for key \(recipientUserIdKey)")
        }
        guard let recipientUserId = UUID(recipientUserIdString) else {
            throw Abort(.badRequest, reason: "Given user ID (\(recipientUserIdString)) must be a valid UUID")
        }
        let circleIdKey = "circleId"
        guard let circleIdString = payload[circleIdKey]?.string else {
            throw Abort(.badRequest, reason: "Payload must contain a string for key \(circleIdKey)")
        }
        guard let circleId = UUID(circleIdString) else {
            throw Abort(.badRequest, reason: "Given circle ID (\(circleIdString)) must be a valid UUID")
        }

        let target = NotificationTarget.android
        let topic = target.format(
            topic: Self.topicForUser(withId: recipientUserId),
            environment: request.application.environment
        )

        guard recipientUserId != authResult.userId.value else {
            throw Abort(.badRequest, reason: "The targeted user cannot be yourself")
        }

        return CirclesRepository(database: request.db)
            .commonCircles(between: [recipientUserId, authResult.userId.value])
            .guard(
                { $0.contains(circleId) },
                else: Abort(.badRequest, reason: "Either you are not in the circle or the targeted user is not")
            )
            .map { _ in [NewMessageNotification(topic: topic, circleId: circleId)] }
    }
}
