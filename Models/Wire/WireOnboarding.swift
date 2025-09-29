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
//  Created by William Pineda on 9/10/25.
//

import Foundation

// MARK: - Wire Models for Onboarding Endpoints
// These mirror your backend JSON exactly (snake_case handled by decoder)

// ✅ CHANGE 1: Add email_style case to enum
enum WireOnboardingStep: String, Decodable {
    case start
    case profile
    case gmail
    case emailStyle = "email_style"  // ← NEW: Email style selection step
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
    // For now you can mirror backend's `user_profile` if needed later
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
    let nextStep: String  // ← This can now be "go_to_email_style_step"
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

// ✅ CHANGE 2: Add helper extension for type-safe next step handling
// MARK: - Helper Extension for Next Step Handling

extension GmailCallbackResponse {
    /// Enum representing possible next steps after Gmail OAuth
    enum NextStepAction {
        case stayOnGmail           // Error occurred, stay on current screen
        case goToEmailStyle        // NEW: Advance to email style selection
        case redirectToMainApp     // Skip onboarding (shouldn't happen normally)
        case goToProfileStep       // Go back to profile (error recovery)
        case completed             // Onboarding complete (legacy behavior)
        case unknown(String)       // Unknown next step value
        
        init(from nextStep: String) {
            switch nextStep {
            case "stay_on_gmail":
                self = .stayOnGmail
            case "go_to_email_style_step":  // ← NEW: Handle the new next step
                self = .goToEmailStyle
            case "redirect_to_main_app":
                self = .redirectToMainApp
            case "go_to_profile_step":
                self = .goToProfileStep
            case "completed":
                self = .completed
            default:
                self = .unknown(nextStep)
            }
        }
    }
    
    /// Convenience property for type-safe next step handling
    var nextStepAction: NextStepAction {
        NextStepAction(from: nextStep)
    }
}
