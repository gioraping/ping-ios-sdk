//
//  PingOneMfaAccount.swift
//  PingOneMFA
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// A value type representing a registered MFA account.
public struct PingOneMfaAccount: Sendable, Equatable {
    /// The geographic region of the account.
    public let region: String
    /// The unique identifier of the account.
    public let id: String
    /// The device identifier associated with the account.
    public let deviceId: String
    /// The environment identifier of the account.
    public let environment: String
    /// The display name of the account.
    public let name: String
    /// The application family of the account.
    public let family: String

    /// Initializes a new instance of `PingOneMfaAccount`.
    public init(region: String, id: String, deviceId: String, environment: String, name: String, family: String) {
        self.region = region
        self.id = id
        self.deviceId = deviceId
        self.environment = environment
        self.name = name
        self.family = family
    }
}
