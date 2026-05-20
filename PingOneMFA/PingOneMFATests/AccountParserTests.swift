//
//  AccountParserTests.swift
//  PingOneMFA
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import PingOneMFA


// MARK: - AccountParser Tests

final class AccountParserTests: XCTestCase {

    // MARK: - Well-formed payload tests

    func testParseSingleRegionSingleUser() {
        // Given
        let deviceInfo: [String: Any] = [
            "regions": [
                [
                    "region": "NorthAmerica",
                    "users": [
                        [
                            "id": "user-id-1",
                            "deviceId": "device-id-1",
                            "environment": "env-id-1",
                            "name": "Test User",
                            "family": "PING_ID"
                        ]
                    ]
                ]
            ]
        ]

        // When
        let accounts = AccountParser.parse(deviceInfo)

        // Then
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts[0].region, "NorthAmerica")
        XCTAssertEqual(accounts[0].id, "user-id-1")
        XCTAssertEqual(accounts[0].deviceId, "device-id-1")
        XCTAssertEqual(accounts[0].environment, "env-id-1")
        XCTAssertEqual(accounts[0].name, "Test User")
        XCTAssertEqual(accounts[0].family, "PING_ID")
    }

    func testParseMultipleRegionsMultipleUsers() {
        // Given
        let deviceInfo: [String: Any] = [
            "regions": [
                [
                    "region": "NorthAmerica",
                    "users": [
                        [
                            "id": "user-na-1",
                            "deviceId": "device-na-1",
                            "environment": "env-na-1",
                            "name": "NA User 1",
                            "family": "PING_ID"
                        ],
                        [
                            "id": "user-na-2",
                            "deviceId": "device-na-2",
                            "environment": "env-na-2",
                            "name": "NA User 2",
                            "family": "PING_ID"
                        ]
                    ]
                ],
                [
                    "region": "Europe",
                    "users": [
                        [
                            "id": "user-eu-1",
                            "deviceId": "device-eu-1",
                            "environment": "env-eu-1",
                            "name": "EU User 1",
                            "family": "PING_ID"
                        ]
                    ]
                ]
            ]
        ]

        // When
        let accounts = AccountParser.parse(deviceInfo)

        // Then
        XCTAssertEqual(accounts.count, 3)

        let naAccounts = accounts.filter { $0.region == "NorthAmerica" }
        XCTAssertEqual(naAccounts.count, 2)

        let euAccounts = accounts.filter { $0.region == "Europe" }
        XCTAssertEqual(euAccounts.count, 1)
        XCTAssertEqual(euAccounts[0].id, "user-eu-1")
    }

    func testParseRegionWithEmptyUsersArray() {
        // Given — region exists but users array is empty
        let deviceInfo: [String: Any] = [
            "regions": [
                [
                    "region": "Australia",
                    "users": []
                ]
            ]
        ]

        // When
        let accounts = AccountParser.parse(deviceInfo)

        // Then
        XCTAssertEqual(accounts.count, 0)
    }

    // MARK: - Edge cases

    func testParseNilDeviceInfo() {
        // When
        let accounts = AccountParser.parse(nil)

        // Then
        XCTAssertEqual(accounts.count, 0)
    }

    func testParseEmptyDictionary() {
        // When
        let accounts = AccountParser.parse([:])

        // Then
        XCTAssertEqual(accounts.count, 0)
    }

    func testParseMissingRegionsKey() {
        // Given — no "regions" key
        let deviceInfo: [String: Any] = [
            "something": "else"
        ]

        // When
        let accounts = AccountParser.parse(deviceInfo)

        // Then
        XCTAssertEqual(accounts.count, 0)
    }

    func testParseRegionsNotAnArray() {
        // Given — "regions" is a String instead of [[String: Any]]
        let deviceInfo: [String: Any] = [
            "regions": "not-an-array"
        ]

        // When
        let accounts = AccountParser.parse(deviceInfo)

        // Then
        XCTAssertEqual(accounts.count, 0)
    }

    func testParseMissingUsersKeyInRegion() {
        // Given — region dict has no "users" key
        let deviceInfo: [String: Any] = [
            "regions": [
                [
                    "region": "NorthAmerica"
                    // "users" key missing
                ]
            ]
        ]

        // When
        let accounts = AccountParser.parse(deviceInfo)

        // Then — silently skipped
        XCTAssertEqual(accounts.count, 0)
    }

    func testParseMissingRequiredUserFields() {
        // Given — user dict is missing the "id" field
        let deviceInfo: [String: Any] = [
            "regions": [
                [
                    "region": "NorthAmerica",
                    "users": [
                        [
                            // "id" missing
                            "deviceId": "device-id-1",
                            "environment": "env-id-1",
                            "name": "Test User",
                            "family": "PING_ID"
                        ]
                    ]
                ]
            ]
        ]

        // When
        let accounts = AccountParser.parse(deviceInfo)

        // Then — user with missing id is silently skipped
        XCTAssertEqual(accounts.count, 0)
    }

    func testParseMixedValidAndInvalidUsers() {
        // Given — one valid user, one missing required field
        let deviceInfo: [String: Any] = [
            "regions": [
                [
                    "region": "NorthAmerica",
                    "users": [
                        [
                            "id": "valid-user",
                            "deviceId": "valid-device",
                            "environment": "valid-env",
                            "name": "Valid User",
                            "family": "PING_ID"
                        ],
                        [
                            // "name" missing
                            "id": "invalid-user",
                            "deviceId": "invalid-device",
                            "environment": "invalid-env",
                            "family": "PING_ID"
                        ]
                    ]
                ]
            ]
        ]

        // When
        let accounts = AccountParser.parse(deviceInfo)

        // Then — only the valid user is returned
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts[0].id, "valid-user")
    }

    func testParseRegionNameDefaultsToEmptyStringWhenMissing() {
        // Given — region dict has no "region" key
        let deviceInfo: [String: Any] = [
            "regions": [
                [
                    // "region" key missing — defaults to ""
                    "users": [
                        [
                            "id": "user-id-1",
                            "deviceId": "device-id-1",
                            "environment": "env-id-1",
                            "name": "Test User",
                            "family": "PING_ID"
                        ]
                    ]
                ]
            ]
        ]

        // When
        let accounts = AccountParser.parse(deviceInfo)

        // Then — user is returned but region defaults to empty string
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts[0].region, "")
    }

    func testParseEmptyRegionsArray() {
        // Given — "regions" is an empty array
        let deviceInfo: [String: Any] = [
            "regions": [[String: Any]]()
        ]

        // When
        let accounts = AccountParser.parse(deviceInfo)

        // Then
        XCTAssertEqual(accounts.count, 0)
    }
}
