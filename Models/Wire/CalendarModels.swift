//
//  CalendarModels.swift
//  voice-gmail-assistant
//
//  Calendar API Response Models
//

import Foundation

// MARK: - Calendar Status Response
struct CalendarStatusResponse: Codable {
    let connected: Bool
    let calendarsAccessible: Int?
    let primaryCalendarAvailable: Bool?
    let canCreateEvents: Bool?
    let connectionHealth: String?
    let expiresAt: String?
    let needsRefresh: Bool?
    
    enum CodingKeys: String, CodingKey {
        case connected
        case calendarsAccessible = "calendars_accessible"
        case primaryCalendarAvailable = "primary_calendar_available"
        case canCreateEvents = "can_create_events"
        case connectionHealth = "connection_health"
        case expiresAt = "expires_at"
        case needsRefresh = "needs_refresh"
    }
}

// MARK: - Calendar Events Response
struct CalendarEventsResponse: Codable {
    let events: [CalendarEvent]
    let totalCount: Int
    let timeRange: CalendarTimeRange?
    let hasMore: Bool?
    
    enum CodingKeys: String, CodingKey {
        case events
        case totalCount = "total_count"
        case timeRange = "time_range"
        case hasMore = "has_more"
    }
}

// MARK: - Calendar Event
struct CalendarEvent: Codable, Identifiable {
    let id: String
    let summary: String?
    let description: String?
    let startTime: String?
    let endTime: String?
    let timezone: String?
    let status: String?
    let location: String?
    let isAllDay: Bool?
    let isBusy: Bool?
    let attendeesCount: Int?
    let created: String?
    let updated: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case summary
        case description
        case startTime = "start_time"
        case endTime = "end_time"
        case timezone
        case status
        case location
        case isAllDay = "is_all_day"
        case isBusy = "is_busy"
        case attendeesCount = "attendees_count"
        case created
        case updated
    }
}

// MARK: - Calendar Time Range
struct CalendarTimeRange: Codable {
    let start: String
    let end: String
}

// MARK: - Calendars List Response
struct CalendarsListResponse: Codable {
    let calendars: [Calendar]
    let totalCount: Int
    let writableCalendars: Int?
    
    enum CodingKeys: String, CodingKey {
        case calendars
        case totalCount = "total_count"
        case writableCalendars = "writable_calendars"
    }
}

// MARK: - Calendar
struct Calendar: Codable, Identifiable {
    let id: String
    let summary: String?
    let description: String?
    let timezone: String?
    let accessRole: String?
    let primary: Bool?
    let selected: Bool?
    let canCreateEvents: Bool?
    let colorId: String?
    let backgroundColor: String?
    let foregroundColor: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case summary
        case description
        case timezone
        case accessRole = "access_role"
        case primary
        case selected
        case canCreateEvents = "can_create_events"
        case colorId = "color_id"
        case backgroundColor = "background_color"
        case foregroundColor = "foreground_color"
    }
}
