//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import FCM
import Foundation
import Vapor

internal struct NotificationsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let notifications = routes
            .grouped(ForwardedAuthAuthenticator(), ForwardedAuthResult.guardMiddleware())
            .grouped("notifications")

        notifications.post(use: postNotification)
    }

    func postNotification(from request: Request) throws -> EventLoopFuture<Response> {
        let authResult = try request.auth.require(ForwardedAuthResult.self)
        let body = try request.content.decode(NotificationNew.self)

        let types: [Notification.Type] = [NewMessageNotification.self]
        guard let notificationType = types.first(where: { $0.type == body.type }) else {
            throw Abort(.badRequest, reason: "Unknown notification type: \(body.type)")
        }
        return try notificationType.make(from: body.payload, and: authResult, considering: request)
            .flatMapThrowing { (notifications: [Notification]) -> [EventLoopFuture<Void>] in
                try notifications.map {
                    try self.sendNotification(notification: $0, authResult: authResult, considering: request)
                }
            }
            .flatMap { EventLoopFuture<Void>.andAllSucceed($0, on: request.eventLoop) }
            .map { Response(status: .noContent) }
    }

    private func sendNotification(
        notification: Notification,
        authResult: ForwardedAuthResult,
        considering request: Request
    ) throws -> EventLoopFuture<Void> {
        var data = notification.data ?? [:]

        data["type"] = data["type"] ?? "\(type(of: notification).type)"
        data["senderUserId"] = data["senderUserId"] ?? authResult.userId.value.uuidString
        data["senderIdentityId"] = data["senderIdentityId"] ?? authResult.identityId.value.uuidString

        let fcmMessage = FCMMessage(
            topic: notification.topic,
            notification: notification.fcmNotification,
            data: data,
            name: notification.name,
            android: notification.android,
            webpush: notification.webpush,
            apns: notification.apns
        )

        request.logger.info("Sending notification on \(notification.topic)")
        return request.fcm.send(fcmMessage)
            .map { _ in }
    }
}
