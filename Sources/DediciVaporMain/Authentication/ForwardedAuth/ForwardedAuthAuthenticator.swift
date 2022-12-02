//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporToolbox
import Fluent
import Foundation
import NIO
import Vapor

internal struct ForwardedAuthAuthenticator {}

extension ForwardedAuthAuthenticator: RequestAuthenticator {
    func authenticate(request: Request) -> EventLoopFuture<Void> {
        guard
            let serverAuthResult = request.headers.nxServerAuthResult,
            let identityIdString = serverAuthResult.extraAuth?["identity"]?.object?["identityId"]?.string,
            let identityId = UUIDv4(identityIdString)
        else { return request.eventLoop.makeSucceededFuture(()) }

        let authResult = ForwardedAuthResult(
            userId: serverAuthResult.userId,
            identityId: identityId,
            subaccounts: serverAuthResult.subaccounts ?? []
        )
        request.auth.login(authResult)
        let identities = IdentitiesRepository(database: request.db)

        return identities
            .find(authResult.identityId.value)
            .flatMap {
                guard let existingIdentity = $0 else {
                    let identity = Identity(id: authResult.identityId.value, ownerId: authResult.userId.value)
                    return identities.create(identity)
                }
                // We already known that the identity id matches but we check the consistency on the user id
                // A mismatch here indicates that the authentication has gone wrong somewhere !
                guard existingIdentity.ownerId == authResult.userId.value else {
                    return request.eventLoop.makeFailedFuture(Abort(.forbidden))
                }

                return request.eventLoop.future()
            }
    }
}
