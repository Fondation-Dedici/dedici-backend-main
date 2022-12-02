//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import DediciVaporFluentToolbox
import DediciVaporToolbox
import Fluent
import Vapor

internal final class CircleInvitation: ResourceModel {
    static let schema = "circle_invitations"

    @ID(key: FieldKeys.id)
    var id: UUID?

    @Field(key: FieldKeys.creationDate)
    var creationDate: Date

    @Field(key: FieldKeys.lastModificationDate)
    var lastModificationDate: Date

    @Field(key: FieldKeys.expirationDate)
    var expirationDate: Date?

    @Field(key: FieldKeys.issuerUserId)
    var issuerUserId: UUID

    @Field(key: FieldKeys.issuerIdentityId)
    var issuerIdentityId: UUID

    @Field(key: FieldKeys.circleId)
    var circleId: UUID

    @Field(key: FieldKeys.activationCode)
    var activationCode: String

    @Field(key: FieldKeys.activationDate)
    var activationDate: Date?

    @Field(key: FieldKeys.activationUserId)
    var activationUserId: UUID?

    @Field(key: FieldKeys.activationIdentityId)
    var activationIdentityId: UUID?

    init() {}

    init(
        id: IDValue? = nil,
        issuerUserId: UUIDv4,
        issuerIdentityId: UUIDv4,
        circleId: UUIDv4,
        maxAge: Int
    ) {
        self.id = id
        self.expirationDate = Date().addingTimeInterval(.init(maxAge))
        self.issuerUserId = issuerUserId.value
        self.issuerIdentityId = issuerIdentityId.value
        self.circleId = circleId.value
        self.activationCode = Self.generateCode()
    }

    private static func generateCode() -> String {
        Data(randomBytes: 6 * 3)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }

    var hasAlreadyBeenActivated: Bool {
        activationDate != nil || activationIdentityId != nil || activationUserId != nil
    }

    func activate(for identityId: Identity.IDValue, and userId: UUID) throws {
        activationDate = .init()
        activationUserId = userId
        activationIdentityId = identityId
    }
}

extension CircleInvitation {
    enum FieldKeys {
        static let id: FieldKey = .id
        static let creationDate: FieldKey = .string("creation_date")
        static let lastModificationDate: FieldKey = .string("last_modification_date")
        static let expirationDate: FieldKey = .string("expiration_date")
        static let issuerUserId: FieldKey = .string("issuer_user_id")
        static let issuerIdentityId: FieldKey = .string("issuer_identity_id")
        static let circleId: FieldKey = .string("circle_id")
        static let activationCode: FieldKey = .string("activation_code")
        static let activationDate: FieldKey = .string("activation_date")
        static let activationUserId: FieldKey = .string("activation_user_id")
        static let activationIdentityId: FieldKey = .string("activation_identity_id")
    }
}

extension CircleInvitation: CanExpire {}

extension CircleInvitation: HasDefaultResponse {
    typealias DefaultResponse = CircleInvitationResponse
}

extension CircleInvitation: HasDefaultCreateOneBody {
    typealias DefaultCreateOneBody = CircleInvitationNew
}
