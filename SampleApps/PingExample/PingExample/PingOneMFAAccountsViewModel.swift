//
//  PingOneMFAAccountsViewModel.swift
//  PingExample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import SwiftUI
import PingOneMFA

/// ViewModel to manage PingOne MFA accounts.
/// Handles lazy SDK initialization, account loading, and error states.
@MainActor
class PingOneMFAAccountsViewModel: ObservableObject {
    @Published var accounts: [PingOneMfaAccount] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Initializes the PingOne MFA SDK if it has not already been initialized.
    /// This is a true no-op — zero state mutation, no async suspension — when the SDK
    /// is already initialized, mirroring the `oathClient == nil` guard in `OathAccountsViewModel`.
    func initialize() async {
        guard !ConfigurationManager.shared.isPingOneMFAInitialized else { return }

        isLoading = true
        do {
            try await ConfigurationManager.shared.initializePingOneMFAClient()
        } catch {
            errorMessage = "Failed to initialize PingOne MFA: \(error.localizedDescription)"
        }
        isLoading = false
    }

    /// Loads the list of paired MFA accounts from the SDK.
    /// Guards on initialization state, mirroring the `oathClient == nil` guard in
    /// `OathAccountsViewModel.loadAccounts()`. If the SDK was never successfully
    /// initialized (e.g. `initialize()` threw), this returns silently rather than
    /// overwriting the initialization error with a less informative "Failed to load
    /// accounts" message.
    func loadAccounts() async {
        guard ConfigurationManager.shared.isPingOneMFAInitialized else {
            // SDK not initialized — silently return so the initialization error
            // surfaced by `initialize()` remains visible to the user.
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            accounts = try await PingOneMFA.getAccounts()
        } catch {
            errorMessage = "Failed to load accounts: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
