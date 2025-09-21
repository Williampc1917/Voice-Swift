//
//  GmailModels.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/20/25.
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
    
    enum CodingKeys: String, CodingKey {
        case connected
        case messagesAccessible = "messages_accessible"
        case connectionHealth = "connection_health"
        case canSendEmail = "can_send_email"
        case canReadEmail = "can_read_email"
        case expiresAt = "expires_at"
        case needsRefresh = "needs_refresh"
    }
}

// MARK: - Gmail Messages Response
struct GmailMessagesResponse: Codable {
    let messages: [GmailMessage]
    let totalFound: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case messages
        case totalFound = "total_found"
        case hasMore = "has_more"
    }
}

// MARK: - Gmail Message
struct GmailMessage: Codable, Identifiable {
    let id: String
    let threadId: String?
    let subject: String?
    let sender: GmailSender
    let snippet: String?
    let bodyText: String?
    let labels: [String]?
    let isUnread: Bool?
    let isStarred: Bool?
    let hasAttachments: Bool?
    let receivedDatetime: String?
    let ageDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case threadId = "thread_id"
        case subject
        case sender
        case snippet
        case bodyText = "body_text"
        case labels
        case isUnread = "is_unread"
        case isStarred = "is_starred"
        case hasAttachments = "has_attachments"
        case receivedDatetime = "received_datetime"
        case ageDescription = "age_description"
    }
}

// MARK: - Gmail Sender
struct GmailSender: Codable {
    let name: String?
    let email: String
}

// MARK: - Gmail Labels Response
struct GmailLabelsResponse: Codable {
    let labels: [GmailLabel]
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case labels
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case displayName = "display_name"
        case type
        case isSystem = "is_system"
        case messagesTotal = "messages_total"
        case messagesUnread = "messages_unread"
    }
}
