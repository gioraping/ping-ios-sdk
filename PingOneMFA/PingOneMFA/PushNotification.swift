//
//  PushNotification.swift
//  PingOneMFA
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
internal import PingOneSDK

/// A value type representing an incoming push notification for MFA authentication.
public struct PushNotification: @unchecked Sendable {
    /// The underlying notification object from the PingOneSDK (internal — not part of the public API).
    internal let notificationObject: NotificationObject

    /// The title of the push notification, extracted from the APNS payload.
    public let title: String?

    /// The message body of the push notification, extracted from the APNS payload.
    public let message: String?

    /// Initializes a new instance of `PushNotification`.
    internal init(notificationObject: NotificationObject, title: String?, message: String?) {
        self.notificationObject = notificationObject
        self.title = title
        self.message = message
    }

    /// Approves the push notification authentication request.
    ///
    /// - Parameters:
    ///   - authMethod: The authentication method to use for approval.
    ///   - numberChallenge: The number matching challenge value, if applicable.
    /// - Throws: `PingOneMFAError` if approval fails.
    public func approve(authMethod: String?, numberChallenge: Int?) async throws {
        throw PingOneMFAError("not implemented")
    }

    /// Denies the push notification authentication request.
    ///
    /// - Throws: `PingOneMFAError` if denial fails.
    public func deny() async throws {
        throw PingOneMFAError("not implemented")
    }
}
