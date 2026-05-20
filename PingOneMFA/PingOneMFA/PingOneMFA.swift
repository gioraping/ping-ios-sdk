//
//  PingOneMFA.swift
//  PingOneMFA
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.

import Foundation
internal import PingOneSDK

/// Actor to manage PingOneMFA SDK state with thread safety
@globalActor
public actor PingOneMFAActor {
    public static let shared = PingOneMFAActor()
}

/// The `PingOneMFA` class provides methods to initialize the SDK and interact with the PingOne MFA service.
@PingOneMFAActor
public class PingOneMFA {
    internal private(set) static var pingOneMFAConfig: PingOneMFAConfig?
    internal private(set) static var isInitialized: Bool = false

    /// Configures the PingOneMFA SDK with the provided configuration.
    /// This method should be called before calling `initialize()`.
    ///
    /// - Parameter block: A closure that configures the `PingOneMFAConfig`.
    public static func config(_ block: (PingOneMFAConfig) -> Void) {
        let pingOneMFAConfig = PingOneMFAConfig()
        block(pingOneMFAConfig)
        self.pingOneMFAConfig = pingOneMFAConfig
    }

    /// Initializes the PingOneMFA SDK with the provided configuration.
    /// This method should be called before using any other methods in the PingOneMFA SDK.
    /// This method is idempotent — if already initialized, it returns immediately.
    ///
    /// - Throws: `PingOneMFAError` if initialization fails or the SDK has not been configured.
    public nonisolated static func initialize() async throws {
        if await isInitialized {
            return
        }

        guard let config = await pingOneMFAConfig, let mfaGeo = config.geo else {
            throw PingOneMFAError("PingOneMFA SDK not configured. Call config() first.")
        }

        let pingOneGeo: PingOneGeo
        switch mfaGeo {
        case .northAmerica:
            pingOneGeo = .NorthAmerica
        case .europe:
            pingOneGeo = .Europe
        case .australia:
            pingOneGeo = .Australia
        case .canada:
            pingOneGeo = .Canada
        case .singapore:
            pingOneGeo = .Singapore
        }

        return try await withCheckedThrowingContinuation { continuation in
            PingOne.configure(geo: pingOneGeo) { error in
                Task { @PingOneMFAActor in
                    if let error = error {
                        self.isInitialized = false
                        continuation.resume(throwing: PingOneMFAError("PingOneSDK initialization failed: \(error.localizedDescription)"))
                    } else {
                        self.isInitialized = true
                        continuation.resume()
                    }
                }
            }
        }
    }

    /// Resets the SDK to uninitialized state (useful for testing)
    internal static func reset() {
        isInitialized = false
        pingOneMFAConfig = nil
    }
}
