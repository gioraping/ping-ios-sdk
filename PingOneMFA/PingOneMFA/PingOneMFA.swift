//
//  PingOneMFA.swift
//  PingOneMFA
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.

import Foundation

/// Actor to manage PingOneMFA SDK state with thread safety
@globalActor
public actor PingOneMFAActor {
    public static let shared = PingOneMFAActor()
}
