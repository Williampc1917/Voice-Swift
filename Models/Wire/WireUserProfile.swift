//
//  WireUserProfile.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/8/25.
//

import Foundation

struct WireUserProfile: Decodable {
    let userId: String
    let email: String
    let displayName: String?
    let isActive: Bool
    let voicePreferences: [String: String]?
    let plan: WirePlan
    let createdAt: String
    let updatedAt: String
}
