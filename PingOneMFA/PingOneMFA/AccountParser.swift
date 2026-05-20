//
//  AccountParser.swift
//  PingOneMFA
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// Internal parser that converts the `deviceInfo` dictionary returned by `PingOne.getInfo(completion:)`
/// into a flat array of `PingOneMfaAccount` values.
///
/// The upstream payload has the shape:
/// ```json
/// {
///   "regions": [
///     {
///       "region": "NorthAmerica",
///       "users": [
///         {
///           "id": "...",
///           "deviceId": "...",
///           "environment": "...",
///           "name": "...",
///           "family": "..."
///         }
///       ]
///     }
///   ]
/// }
/// ```
/// The parser walks `regions[].users[]` and flatMaps into `[PingOneMfaAccount]`.
/// Missing or malformed keys are silently skipped — the parser is best-effort and never throws.
internal struct AccountParser {

    /// Parses a `deviceInfo` dictionary (from `PingOne.getInfo(completion:)`) into
    /// a flat list of `PingOneMfaAccount` values.
    ///
    /// - Parameter deviceInfo: The raw dictionary returned by `PingOne.getInfo`. May be `nil`.
    /// - Returns: An array of parsed accounts (empty if `deviceInfo` is `nil`, empty, or malformed).
    internal static func parse(_ deviceInfo: [String: Any]?) -> [PingOneMfaAccount] {
        guard let deviceInfo = deviceInfo,
              let regions = deviceInfo["regions"] as? [[String: Any]] else {
            return []
        }

        return regions.flatMap { regionDict -> [PingOneMfaAccount] in
            let regionName = regionDict["region"] as? String ?? ""
            guard let users = regionDict["users"] as? [[String: Any]] else {
                return []
            }
            return users.compactMap { userDict -> PingOneMfaAccount? in
                guard
                    let id = userDict["id"] as? String,
                    let deviceId = userDict["deviceId"] as? String,
                    let environment = userDict["environment"] as? String,
                    let name = userDict["name"] as? String,
                    let family = userDict["family"] as? String
                else {
                    return nil
                }
                return PingOneMfaAccount(
                    region: regionName,
                    id: id,
                    deviceId: deviceId,
                    environment: environment,
                    name: name,
                    family: family
                )
            }
        }
    }
}
