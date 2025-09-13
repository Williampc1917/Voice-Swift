//
//  WireOnboarding.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.
//


//
//  WireOnboarding.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/9/25.
//

import Foundation

// MARK: - Wire Models for Onboarding Endpoints
// These mirror your backend JSON exactly (snake_case handled by decoder)

enum WireOnboardingStep: String, Decodable {
    case start
    case profile
    case gmail
    case completed
}

struct WireOnboardingStatus: Decodable {
    let step: WireOnboardingStep
    let onboardingCompleted: Bool
    let gmailConnected: Bool
    let timezone: String
}

struct WireOnboardingProfileUpdateResponse: Decodable {
    let success: Bool
    let nextStep: String   // usually "gmail"
    let message: String
}

struct WireOnboardingCompleteResponse: Decodable {
    let success: Bool
    let message: String
    // For now you can mirror backend’s `user_profile` if needed later
    // let userProfile: WireUserProfile
}

struct GmailAuthURLResponse: Decodable {
    let authUrl: String
    let state: String
}

struct GmailCallbackResponse: Codable {
    let success: Bool
    let message: String
    let gmailConnected: Bool
    let nextStep: String
}

struct GmailStatusResponse: Codable {
    let connected: Bool
    let provider: String?
    let scope: String?
    let expiresAt: String?
    let needsRefresh: Bool
}

struct GmailDisconnectResponse: Codable {
    let success: Bool
    let message: String
    let gmailConnected: Bool
}
struct GmailRetrieveResponse: Codable {
    let success: Bool
    let code: String
    let state: String
    let timestamp: String
    let message: String
}
