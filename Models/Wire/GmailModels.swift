//
//  GmailModels.swift
//  voice-gmail-assistant
//
//  Updated to match exact backend API specification
//

import Foundation

// MARK: - Gmail Status Response
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
    
    enum CodingKeys: String, CodingKey {
        case connected
        case messagesAccessible = "messages_accessible"
        case connectionHealth = "connection_health"
        case canSendEmail = "can_send_email"
        case canReadEmail = "can_read_email"
        case expiresAt = "expires_at"
        case needsRefresh = "needs_refresh"
        case healthDetails = "health_details"
        case quotaRemaining = "quota_remaining"
    }
}

// MARK: - Gmail Health Details
struct GmailHealthDetails: Codable {
    let accessTokenValid: Bool?
    let refreshTokenValid: Bool?
    let lastActivity: String?
    
    enum CodingKeys: String, CodingKey {
        case accessTokenValid = "access_token_valid"
        case refreshTokenValid = "refresh_token_valid"
        case lastActivity = "last_activity"
    }
}

// MARK: - Gmail Quota Remaining
struct GmailQuotaRemaining: Codable {
    let dailyQuota: Int?
    let quotaUsed: Int?
    
    enum CodingKeys: String, CodingKey {
        case dailyQuota = "daily_quota"
        case quotaUsed = "quota_used"
    }
}

// MARK: - Messages List Response (FIXED to match API spec exactly)
struct GmailMessagesResponse: Codable {
    let messages: [GmailMessage]
    let totalFound: Int?           // Make optional
    let queryParameters: QueryParameters?
    let hasMore: Bool?             // Make optional
    let nextPageToken: String?

    enum CodingKeys: String, CodingKey {
        case messages
        case totalFound = "total_count"
        case queryParameters = "query_parameters"
        case hasMore = "has_more"
        case nextPageToken = "next_page_token"
    }
}

// MARK: - Query Parameters
struct QueryParameters: Codable {
    let maxResults: Int?
    let onlyUnread: Bool?
    let labelIds: [String]?
    let query: String?
    
    enum CodingKeys: String, CodingKey {
        case maxResults = "max_results"
        case onlyUnread = "only_unread"
        case labelIds = "label_ids"
        case query
    }
}

// MARK: - Gmail Message (Updated with all fields from API spec)
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case threadId = "thread_id"
        case subject
        case sender
        case recipient
        case cc
        case bcc
        case snippet
        case bodyText = "body_text"
        case bodyHtml = "body_html"
        case attachments
        case labels
        case isUnread = "is_unread"
        case isStarred = "is_starred"
        case isImportant = "is_important"
        case hasAttachments = "has_attachments"
        case receivedDatetime = "received_datetime"
        case senderDisplay = "sender_display"
        case bodyPreview = "body_preview"
        case sizeEstimate = "size_estimate"
        case ageDescription = "age_description"
        case priorityLevel = "priority_level"
        case isActionable = "is_actionable"
    }
}

// MARK: - Gmail Sender
struct GmailSender: Codable {
    let name: String?
    let email: String
}

// MARK: - Gmail Recipient
struct GmailRecipient: Codable {
    let name: String?
    let email: String
}

// MARK: - Gmail Labels Response
struct GmailLabelsResponse: Codable {
    let labels: [GmailLabel]
    let systemLabels: [GmailLabel]?
    let userLabels: [GmailLabel]?
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case labels
        case systemLabels = "system_labels"
        case userLabels = "user_labels"
        case totalCount = "total_count"
    }
}

// MARK: - Gmail Label
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case displayName = "display_name"
        case type
        case isSystem = "is_system"
        case messagesTotal = "messages_total"
        case messagesUnread = "messages_unread"
        case threadsTotal = "threads_total"
        case threadsUnread = "threads_unread"
    }
}

// MARK: - Search Messages Request
struct SearchMessagesRequest: Codable {
    let query: String
    let maxResults: Int
    
    enum CodingKeys: String, CodingKey {
        case query
        case maxResults = "max_results"
    }
}

// MARK: - Search Results Response
struct SearchResultsResponse: Codable {
    let messages: [GmailMessage]
    let query: String
    let totalFound: Int
    let hasMore: Bool
    let unreadCount: Int
    let highPriorityCount: Int
    let actionableCount: Int
    
    enum CodingKeys: String, CodingKey {
        case messages
        case query
        case totalFound = "total_found"
        case hasMore = "has_more"
        case unreadCount = "unread_count"
        case highPriorityCount = "high_priority_count"
        case actionableCount = "actionable_count"
    }
}

// MARK: - Send Email Request
struct SendEmailRequest: Codable {
    let to: [String]
    let subject: String
    let body: String
    let cc: [String]?
    let bcc: [String]?
    let replyTo: String?
    let replyToMessageId: String?
    
    enum CodingKeys: String, CodingKey {
        case to
        case subject
        case body
        case cc
        case bcc
        case replyTo = "reply_to"
        case replyToMessageId = "reply_to_message_id"
    }
}

// MARK: - Send Email Response
struct SendEmailResponse: Codable {
    let success: Bool
    let messageId: String
    let threadId: String
    let message: String
    let recipients: EmailRecipients
    
    enum CodingKeys: String, CodingKey {
        case success
        case messageId = "message_id"
        case threadId = "thread_id"
        case message
        case recipients
    }
}

// MARK: - Email Recipients
struct EmailRecipients: Codable {
    let to: [String]
    let cc: [String]
    let bcc: [String]
}

// MARK: - Modify Message Response
struct ModifyMessageResponse: Codable {
    let success: Bool
    let message: GmailMessage
    let changesMade: [String]
    let messageText: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case changesMade = "changes_made"
        case messageText = "message_text"
    }
}

// MARK: - Delete Message Response
struct DeleteMessageResponse: Codable {
    let success: Bool
    let messageId: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case messageId = "message_id"
        case message
    }
}

// MARK: - Voice Assistant Responses
struct VoiceInboxSummaryResponse: Codable {
    let unreadCount: Int
    let totalRecent: Int
    let highPriorityCount: Int
    let actionableCount: Int
    let unreadMessages: [VoiceMessage]
    let voiceSummary: String
    
    enum CodingKeys: String, CodingKey {
        case unreadCount = "unread_count"
        case totalRecent = "total_recent"
        case highPriorityCount = "high_priority_count"
        case actionableCount = "actionable_count"
        case unreadMessages = "unread_messages"
        case voiceSummary = "voice_summary"
    }
}

// MARK: - Voice Message
struct VoiceMessage: Codable, Identifiable {
    let id: String
    let subject: String
    let sender: String
    let preview: String?
    let age: String?
    let priority: String?
    let actionable: Bool?
}

// MARK: - Voice Today Emails Response
struct VoiceTodayEmailsResponse: Codable {
    let totalToday: Int
    let unreadToday: Int
    let importantToday: Int
    let messages: [VoiceMessage]
    let voiceSummary: String
    
    enum CodingKeys: String, CodingKey {
        case totalToday = "total_today"
        case unreadToday = "unread_today"
        case importantToday = "important_today"
        case messages
        case voiceSummary = "voice_summary"
    }
}

// MARK: - Gmail Thread Response
struct GmailThreadResponse: Codable, Identifiable {
    let id: String
    let snippet: String
    let subject: String
    let messageCount: Int
    let hasUnread: Bool
    let participants: [[String: String]]
    let latestMessage: GmailMessage?
    let messages: [GmailMessage]

    enum CodingKeys: String, CodingKey {
        case id
        case snippet
        case subject
        case messageCount = "message_count"
        case hasUnread = "has_unread"
        case participants
        case latestMessage = "latest_message"
        case messages
    }
}
