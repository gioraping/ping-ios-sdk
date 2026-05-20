//
//  MockPingOneMFA.swift
//  PingOneMFA
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//
import Foundation
@testable import PingOneMFA

class MockPingOneMFA {
    nonisolated(unsafe) static var shouldThrowError = false
    nonisolated(unsafe) static var errorMessage = "Operation failed"
    nonisolated(unsafe) static var initializeCalled = false
    nonisolated(unsafe) static var registerCalled = false
    nonisolated(unsafe) static var pairCalled = false
    nonisolated(unsafe) static var getAccountsCalled = false
    nonisolated(unsafe) static var collectOtpCalled = false
    nonisolated(unsafe) static var collectPushCalled = false
    nonisolated(unsafe) static var collectMobilePayloadCalled = false
    nonisolated(unsafe) static var configCalled = false
    nonisolated(unsafe) static var lastConfig: PingOneMFAConfig?

    // Return values for happy-path tests
    nonisolated(unsafe) static var accountsReturnValue: [PingOneMfaAccount] = []
    nonisolated(unsafe) static var otpReturnValue = OtpCodeInfo(code: "123456", secondsRemaining: 30)
    nonisolated(unsafe) static var mobilePayloadReturnValue = "mockMobilePayload"

    static func reset() {
        shouldThrowError = false
        errorMessage = "Operation failed"
        initializeCalled = false
        registerCalled = false
        pairCalled = false
        getAccountsCalled = false
        collectOtpCalled = false
        collectPushCalled = false
        collectMobilePayloadCalled = false
        configCalled = false
        lastConfig = nil
        accountsReturnValue = []
        otpReturnValue = OtpCodeInfo(code: "123456", secondsRemaining: 30)
        mobilePayloadReturnValue = "mockMobilePayload"
    }

    @PingOneMFAActor
    static func config(_ closure: (PingOneMFAConfig) -> Void) async {
        configCalled = true
        let config = PingOneMFAConfig()
        closure(config)
        lastConfig = config
    }

    static func initialize() async throws {
        initializeCalled = true
        if shouldThrowError {
            throw TestMFAError.initFailed(errorMessage)
        }
    }

    static func register(pushToken: Data) async throws {
        registerCalled = true
        if shouldThrowError {
            throw TestMFAError.operationFailed(errorMessage)
        }
    }

    static func pair(pairingKey: String) async throws {
        pairCalled = true
        if shouldThrowError {
            throw TestMFAError.operationFailed(errorMessage)
        }
    }

    static func getAccounts() async throws -> [PingOneMfaAccount] {
        getAccountsCalled = true
        if shouldThrowError {
            throw TestMFAError.operationFailed(errorMessage)
        }
        return accountsReturnValue
    }

    static func collectOtp() async throws -> OtpCodeInfo {
        collectOtpCalled = true
        if shouldThrowError {
            throw TestMFAError.operationFailed(errorMessage)
        }
        return otpReturnValue
    }

    static func collectMobilePayload() async throws -> String {
        collectMobilePayloadCalled = true
        if shouldThrowError {
            throw TestMFAError.operationFailed(errorMessage)
        }
        return mobilePayloadReturnValue
    }
}


enum TestMFAError: LocalizedError {
    case initFailed(String)
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .initFailed(let message):
            return message
        case .operationFailed(let message):
            return message
        }
    }
}
