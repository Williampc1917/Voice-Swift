//
//  EmailStyleModels.swift
//  voice-gmail-assistant
//
//  Email Style API Response Models
//  Matches backend API specification exactly
//

import Foundation

// MARK: - Rate Limit Info (NO CodingKeys - relies on convertFromSnakeCase)
struct RateLimitInfo: Codable {
    let canExtract: Bool
    let usedToday: Int
    let dailyLimit: Int
    let hoursUntilReset: Double
}

// MARK: - Email Style Example (NO CodingKeys - relies on convertFromSnakeCase)
struct EmailStyleExample: Codable {
    let greeting: String
    let closing: String
    let tone: String
}

// MARK: - Email Style Option (NO CodingKeys - relies on convertFromSnakeCase)
struct EmailStyleOption: Codable, Identifiable {
    let name: String
    let description: String
    let example: EmailStyleExample
    let available: Bool
    let rateLimitInfo: RateLimitInfo?
    
    // Computed ID for SwiftUI List/ForEach
    var id: String { name }
}

// MARK: - Email Style Status Response (NO CodingKeys - relies on convertFromSnakeCase)
struct EmailStyleStatusResponse: Codable {
    let currentStep: String
    let styleSelected: String?
    let availableOptions: [EmailStyleOption]
    let canAdvance: Bool
    let rateLimitInfo: RateLimitInfo?
}

// MARK: - Email Style Selection Response (NO CodingKeys - relies on convertFromSnakeCase)
struct EmailStyleSelectionResponse: Codable {
    let success: Bool
    let styleType: String
    let nextStep: String
    let message: String
}

// MARK: - Style Profile Components (for Custom Style)
// These represent the AI-extracted style characteristics

struct GreetingStyle: Codable {
    let style: String
    let warmth: String
}

struct ClosingStyle: Codable {
    let styles: [String]
    let includesName: Bool
}

struct ToneStyle: Codable {
    let formality: Int
    let directness: Int
    let enthusiasm: Int
    let politeness: Int
}

// MARK: - Style Profile (NO CodingKeys - relies on convertFromSnakeCase)
struct StyleProfile: Codable {
    let greeting: GreetingStyle
    let closing: ClosingStyle
    let tone: ToneStyle
    // Note: Backend may include additional fields like sentenceStructure, vocabulary, etc.
    // Using a flexible approach here - can decode partial data
}

// MARK: - Rate Limit Response Info (for error responses)
struct RateLimitResponseInfo: Codable {
    let used: Int
    let limit: Int
    let resetTime: String
}

// MARK: - Custom Email Style Response (NO CodingKeys - relies on convertFromSnakeCase)
struct CustomEmailStyleResponse: Codable {
    let success: Bool
    let styleProfile: StyleProfile?
    let extractionGrade: String?
    let errorMessage: String?
    let rateLimitInfo: RateLimitResponseInfo?
    let nextStep: String?
}

// MARK: - Helper Extensions

extension EmailStyleOption {
    /// Returns a user-friendly display of rate limit status
    var rateLimitDisplay: String? {
        guard let info = rateLimitInfo else { return nil }
        
        if !info.canExtract {
            let hours = Int(info.hoursUntilReset)
            return "Used \(info.usedToday)/\(info.dailyLimit) today. Resets in \(hours)h"
        }
        
        return "\(info.dailyLimit - info.usedToday) remaining today"
    }
    
    /// Returns icon name for this style option
    var iconName: String {
        switch name.lowercased() {
        case "casual":
            return "bubble.left.and.bubble.right"
        case "professional":
            return "briefcase"
        case "custom":
            return "brain.head.profile"
        default:
            return "envelope"
        }
    }
}

extension CustomEmailStyleResponse {
    /// Returns user-friendly error message
    var friendlyError: String {
        if let error = errorMessage {
            return error
        }
        
        if !success {
            return "Failed to create custom style. Please try again."
        }
        
        return "Unknown error occurred"
    }
    
    /// Returns true if this is a rate limit error
    var isRateLimitError: Bool {
        errorMessage?.contains("daily limit") ?? false ||
        errorMessage?.contains("rate limit") ?? false
    }
    
    /// Returns display text for extraction grade
    var gradeDisplay: String? {
        guard let grade = extractionGrade else { return nil }
        
        switch grade {
        case "A":
            return "Excellent - Your style was captured accurately!"
        case "B":
            return "Good - Your style was captured well."
        case "C":
            return "Fair - Consider providing more varied examples."
        default:
            return nil
        }
    }
}

extension RateLimitInfo {
    /// Returns a countdown string (e.g., "8 hours" or "45 minutes")
    var resetCountdown: String {
        let hours = Int(hoursUntilReset)
        
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
        
        let minutes = Int((hoursUntilReset - Double(hours)) * 60)
        return "\(minutes) minute\(minutes == 1 ? "" : "s")"
    }
    
    /// Returns percentage of daily limit used (0.0 to 1.0)
    var usagePercentage: Double {
        guard dailyLimit > 0 else { return 0 }
        return Double(usedToday) / Double(dailyLimit)
    }
}
