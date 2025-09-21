//
//  GmailModels.swift
//  voice-gmail-assistant
//
//  Updated to match exact backend API specification
//

import Foundation

// MARK: - Gmail Status Response (NO CodingKeys - relies on convertFromSnakeCase)
struct GmailStatusResponse: Codable {
    let connected: Bool
    let messagesAccessible: Int?
    let connectionHealth: String?
    let canSendEmail: Bool?
    let canReadEmail: Bool?
    let expiresAt: String?
    let needsRefresh: Bool?
    let healthDetails: GmailHealthDetails?
    let quotaRemaining: GmailQuotaRemaining?
}

// MARK: - Gmail Health Details (NO CodingKeys - relies on convertFromSnakeCase)
struct GmailHealthDetails: Codable {
    let gmailApiConnectivity: String?
    let quotaRemaining: Int?
}

struct GmailHealthResponse: Codable {
    let healthy: Bool
    let service: String
    let timestamp: String
    let googleGmailApi: HealthStatus
    let oauthTokens: HealthStatus
    let databaseConnectivity: HealthStatus
    let supportedOperations: [String]
    let apiVersion: String
    let issuesFound: [String]
    let recommendations: [String]
}

// MARK: - Gmail Quota Remaining (NO CodingKeys - relies on convertFromSnakeCase)
struct GmailQuotaRemaining: Codable {
    let dailyLimit: Int
    let used: Int
    let remaining: Int
}

// MARK: - Messages List Response (NO CodingKeys - relies on convertFromSnakeCase)
struct GmailMessagesResponse: Codable {
    let messages: [GmailMessage]
    let totalFound: Int?
    let queryParameters: QueryParameters?
    let hasMore: Bool?
    let nextPageToken: String?
}

// MARK: - Query Parameters (NO CodingKeys - relies on convertFromSnakeCase)
struct QueryParameters: Codable {
    let maxResults: Int?
    let onlyUnread: Bool?
    let labelIds: [String]?
    let query: String?
}

// MARK: - Gmail Message (NO CodingKeys - relies on convertFromSnakeCase)
struct GmailMessage: Codable, Identifiable {
    let id: String
    let threadId: String?
    let subject: String?
    let sender: GmailSender
    let recipient: GmailRecipient?
    let cc: [GmailSender]?
    let bcc: [GmailSender]?
    let snippet: String?
    let bodyText: String?
    let bodyHtml: String?
    let attachments: [String]?
    let labels: [String]?
    let isUnread: Bool?
    let isStarred: Bool?
    let isImportant: Bool?
    let hasAttachments: Bool?
    let receivedDatetime: String?
    let senderDisplay: String?
    let bodyPreview: String?
    let sizeEstimate: Int?
    let ageDescription: String?
    let priorityLevel: String?
    let isActionable: Bool?
}
// Alias to clarify that GET /gmail/messages/{message_id} returns one message
typealias GmailMessageResponse = GmailMessage

// MARK: - Gmail Sender (NO CodingKeys needed - simple fields)
struct GmailSender: Codable {
    let name: String?
    let email: String
}

// MARK: - Gmail Recipient (NO CodingKeys needed - simple fields)
struct GmailRecipient: Codable {
    let name: String?
    let email: String
}

// MARK: - Gmail Labels Response (NO CodingKeys - relies on convertFromSnakeCase)
struct GmailLabelsResponse: Codable {
    let labels: [GmailLabel]
    let systemLabels: [GmailLabel]?
    let userLabels: [GmailLabel]?
    let totalCount: Int
}

// MARK: - Gmail Label (NO CodingKeys - relies on convertFromSnakeCase)
struct GmailLabel: Codable, Identifiable {
    let id: String
    let name: String
    let displayName: String?
    let type: String?
    let isSystem: Bool?
    let messagesTotal: Int?
    let messagesUnread: Int?
    let threadsTotal: Int?
    let threadsUnread: Int?
}

// MARK: - Search Messages Request (NO CodingKeys - relies on convertFromSnakeCase)
struct SearchMessagesRequest: Codable {
    let query: String
    let maxResults: Int
}

// MARK: - Search Results Response (NO CodingKeys - relies on convertFromSnakeCase)
struct SearchResultsResponse: Codable {
    let messages: [GmailMessage]
    let query: String
    let totalFound: Int
    let hasMore: Bool
    let unreadCount: Int
    let highPriorityCount: Int
    let actionableCount: Int
}

// MARK: - Send Email Request (NO CodingKeys - relies on convertFromSnakeCase)
struct SendEmailRequest: Codable {
    let to: [String]
    let subject: String
    let body: String
    let cc: [String]?
    let bcc: [String]?
    let replyTo: String?
    let replyToMessageId: String?
}

// MARK: - Send Email Response (NO CodingKeys - relies on convertFromSnakeCase)
struct SendEmailResponse: Codable {
    let success: Bool
    let messageId: String
    let threadId: String
    let message: String
    let recipients: EmailRecipients
}

// MARK: - Email Recipients (NO CodingKeys needed - simple fields)
struct EmailRecipients: Codable {
    let to: [String]
    let cc: [String]
    let bcc: [String]
}

// MARK: - Modify Message Response (NO CodingKeys - relies on convertFromSnakeCase)
struct ModifyMessageResponse: Codable {
    let success: Bool
    let message: GmailMessage
    let changesMade: [String]
    let messageText: String
}

// MARK: - Delete Message Response (NO CodingKeys - relies on convertFromSnakeCase)
struct DeleteMessageResponse: Codable {
    let success: Bool
    let messageId: String
    let message: String
}

// MARK: - Voice Assistant Responses (NO CodingKeys - relies on convertFromSnakeCase)
struct VoiceInboxSummaryResponse: Codable {
    let unreadCount: Int
    let totalRecent: Int
    let highPriorityCount: Int
    let actionableCount: Int
    let unreadMessages: [VoiceMessage]
    let voiceSummary: String
}

// MARK: - Voice Message (NO CodingKeys needed - simple fields)
struct VoiceMessage: Codable, Identifiable {
    let id: String
    let subject: String
    let sender: String
    let preview: String?
    let age: String?
    let priority: String?
    let actionable: Bool?
}

// MARK: - Voice Today Emails Response (NO CodingKeys - relies on convertFromSnakeCase)
struct VoiceTodayEmailsResponse: Codable {
    let totalToday: Int
    let unreadToday: Int
    let importantToday: Int
    let messages: [VoiceMessage]
    let voiceSummary: String
}

// MARK: - Gmail Thread Response (NO CodingKeys - relies on convertFromSnakeCase)
struct GmailThreadResponse: Codable, Identifiable {
    let id: String
    let snippet: String
    let subject: String
    let messageCount: Int
    let hasUnread: Bool
    let participants: [[String: String]]
    let latestMessage: GmailMessage?
    let messages: [GmailMessage]
}
