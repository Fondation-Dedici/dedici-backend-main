//
// Copyright (c) 2022 Dediĉi
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

internal enum CircleRole: String, Hashable, Content, CaseIterable {
    case administrator
    case member

    var priority: Int {
        switch self {
        case .member: return 1
        case .administrator: return 2
        }
    }

    var canForceExpireInvitations: Bool {
        switch self {
        case .administrator: return true
        case .member: return false
        }
    }

    var canSeeInvitations: Bool {
        switch self {
        case .administrator: return true
        case .member: return false
        }
    }

    var canInviteNewMembers: Bool {
        switch self {
        case .administrator: return true
        case .member: return false
        }
    }

    var canAddNewMembersDirectly: Bool {
        switch self {
        case .administrator: return true
        case .member: return false
        }
    }

    var canDeleteCircle: Bool {
        switch self {
        case .administrator: return true
        case .member: return false
        }
    }

    var canWriteGroupOwnedItems: Bool {
        switch self {
        case .administrator: return true
        case .member: return false
        }
    }

    var canUpdatePublicContent: Bool { true }

    func canKickUser(with role: CircleRole) -> Bool { self >= role }
    func canCreateUser(with role: CircleRole) -> Bool { self >= role }
    func canChangeUserRole(from currentRole: CircleRole, to futureRole: CircleRole) -> Bool {
        self >= currentRole && self >= futureRole
    }

    static var `default`: CircleRole { .member }

    static var highest: CircleRole { .administrator }
}

extension CircleRole: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.priority < rhs.priority }
}
