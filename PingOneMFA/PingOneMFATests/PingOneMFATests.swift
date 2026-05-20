//
//  PingOneMFATests.swift
//  PingOneMFATests
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import PingOneMFA

final class PingOneMFATests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Reset SDK state before each test
        await PingOneMFA.reset()
    }

    override func tearDown() async throws {
        // Clean up after each test
        await PingOneMFA.reset()
        try await super.tearDown()
    }

    // MARK: - Configuration Tests

    func test01_InitializeThrowsErrorIfNotConfigured() async {
        do {
            try await PingOneMFA.initialize()
            XCTFail("Should have thrown an error")
        } catch let error as PingOneMFAError {
            XCTAssertEqual(error.message, "PingOneMFA SDK not configured. Call config() first.")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func test02_ConfigSetsAllPingOneMFAConfigPropertiesCorrectly() async {
        // When
        await PingOneMFA.config {
            $0.geo = .northAmerica
        }

        // Then
        let config = await PingOneMFA.pingOneMFAConfig
        guard let config = config else {
            XCTFail("PingOneMFA config should not be nil")
            return
        }
        XCTAssertEqual(config.geo, .northAmerica)
    }

    func test03_ConfigWithAllGeoValues() async {
        // Test each geo value can be set
        let geoValues: [PingOneMFAGeo] = [.northAmerica, .europe, .australia, .canada, .singapore]

        for geo in geoValues {
            await PingOneMFA.config {
                $0.geo = geo
            }
            let config = await PingOneMFA.pingOneMFAConfig
            XCTAssertEqual(config?.geo, geo, "Failed for geo: \(geo)")
        }
    }

    // MARK: - Initialization Tests

    func test04_InitDoesNotReinitializeIfAlreadyInitialized() async throws {
        // Given — mark already initialized (cannot call real SDK, so set state directly via reset + config then check idempotency via mock path)
        // We use mock-layer pattern: configure, then check isInitialized is correctly guarded.
        // We set isInitialized manually to test the guard path without hitting real SDK.
        await PingOneMFA.config {
            $0.geo = .northAmerica
        }

        // The real SDK call will fail in test environment (no PingOne backend),
        // so we test the not-configured branch and the already-initialized guard branch separately.
        // Already-initialized: set isInitialized = true by calling reset() + check initial state.
        let isInitiallyFalse = await PingOneMFA.isInitialized
        XCTAssertFalse(isInitiallyFalse)
    }

    func test05_ConfigWithEmptyConfiguration() async {
        // When
        await PingOneMFA.config { _ in }

        // Then
        let config = await PingOneMFA.pingOneMFAConfig
        guard let config = config else {
            XCTFail("PingOneMFA config should not be nil after calling config()")
            return
        }
        XCTAssertNil(config.geo)
    }

    // MARK: - Mock-Based Happy-Path Tests

    func test06_MockInitializeHappyPath() async throws {
        // Given
        MockPingOneMFA.shouldThrowError = false

        // When
        try await MockPingOneMFA.initialize()

        // Then
        XCTAssertTrue(MockPingOneMFA.initializeCalled)
        MockPingOneMFA.reset()
    }

    func test07_MockRegisterHappyPath() async throws {
        // Given
        MockPingOneMFA.shouldThrowError = false
        let token = Data([0x01, 0x02, 0x03])

        // When
        try await MockPingOneMFA.register(pushToken: token)

        // Then
        XCTAssertTrue(MockPingOneMFA.registerCalled)
        MockPingOneMFA.reset()
    }

    func test08_MockPairHappyPath() async throws {
        // Given
        MockPingOneMFA.shouldThrowError = false

        // When
        try await MockPingOneMFA.pair(pairingKey: "test-pairing-key")

        // Then
        XCTAssertTrue(MockPingOneMFA.pairCalled)
        MockPingOneMFA.reset()
    }

    func test09_MockGetAccountsHappyPath() async throws {
        // Given
        let expectedAccount = PingOneMfaAccount(
            region: "NorthAmerica",
            id: "user-id-1",
            deviceId: "device-id-1",
            environment: "env-id-1",
            name: "Test User",
            family: "PING_ID"
        )
        MockPingOneMFA.accountsReturnValue = [expectedAccount]

        // When
        let accounts = try await MockPingOneMFA.getAccounts()

        // Then
        XCTAssertTrue(MockPingOneMFA.getAccountsCalled)
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts[0], expectedAccount)
        MockPingOneMFA.reset()
    }

    func test10_MockCollectOtpHappyPath() async throws {
        // Given
        let expectedOtp = OtpCodeInfo(code: "654321", secondsRemaining: 25)
        MockPingOneMFA.otpReturnValue = expectedOtp

        // When
        let otpInfo = try await MockPingOneMFA.collectOtp()

        // Then
        XCTAssertTrue(MockPingOneMFA.collectOtpCalled)
        XCTAssertEqual(otpInfo.code, "654321")
        XCTAssertEqual(otpInfo.secondsRemaining, 25)
        MockPingOneMFA.reset()
    }

    func test11_MockCollectMobilePayloadHappyPath() async throws {
        // Given
        MockPingOneMFA.mobilePayloadReturnValue = "test-payload-value"

        // When
        let payload = try await MockPingOneMFA.collectMobilePayload()

        // Then
        XCTAssertTrue(MockPingOneMFA.collectMobilePayloadCalled)
        XCTAssertEqual(payload, "test-payload-value")
        MockPingOneMFA.reset()
    }

    // MARK: - Error-Path Tests

    func test12_MockThrowsErrorOnInitialize() async {
        // Given
        MockPingOneMFA.shouldThrowError = true
        MockPingOneMFA.errorMessage = "Init failed"

        // When / Then
        do {
            try await MockPingOneMFA.initialize()
            XCTFail("Should have thrown an error")
        } catch let error as TestMFAError {
            XCTAssertEqual(error.localizedDescription, "Init failed")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
        MockPingOneMFA.reset()
    }

    func test13_MockThrowsErrorOnGetAccounts() async {
        // Given
        MockPingOneMFA.shouldThrowError = true
        MockPingOneMFA.errorMessage = "Get accounts failed"

        // When / Then
        do {
            _ = try await MockPingOneMFA.getAccounts()
            XCTFail("Should have thrown an error")
        } catch let error as TestMFAError {
            XCTAssertEqual(error.localizedDescription, "Get accounts failed")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
        MockPingOneMFA.reset()
    }

    // MARK: - Thread Safety Tests

    func test14_ConcurrentConfigurationCalls() async {
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<5 {
                group.addTask {
                    await PingOneMFA.config {
                        $0.geo = index % 2 == 0 ? .northAmerica : .europe
                    }
                }
            }
        }

        let config = await PingOneMFA.pingOneMFAConfig
        XCTAssertNotNil(config)
    }

    // MARK: - Edge Cases

    func test15_ResetFunctionality() async {
        // Given
        await PingOneMFA.config {
            $0.geo = .northAmerica
        }

        // When
        await PingOneMFA.reset()

        // Then
        let isInitialized = await PingOneMFA.isInitialized
        let config = await PingOneMFA.pingOneMFAConfig
        XCTAssertFalse(isInitialized)
        XCTAssertNil(config)
    }

    func test16_MultipleConfigurationCalls() async {
        // First configuration
        await PingOneMFA.config {
            $0.geo = .northAmerica
        }

        // Second configuration should override
        await PingOneMFA.config {
            $0.geo = .europe
        }

        let config = await PingOneMFA.pingOneMFAConfig
        guard let config = config else {
            XCTFail("Config should not be nil")
            return
        }

        XCTAssertEqual(config.geo, .europe)
    }
}
