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
