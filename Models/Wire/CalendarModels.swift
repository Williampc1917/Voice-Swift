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
    let healthDetails: CalendarHealthDetails?
    let expiresAt: String?
    let needsRefresh: Bool?
    
    enum CodingKeys: String, CodingKey {
        case connected
        case calendarsAccessible = "calendars_accessible"
        case primaryCalendarAvailable = "primary_calendar_available"
        case canCreateEvents = "can_create_events"
        case connectionHealth = "connection_health"
        case healthDetails = "health_details"
        case expiresAt = "expires_at"
        case needsRefresh = "needs_refresh"
    }
}

// MARK: - Calendar Health Details
struct CalendarHealthDetails: Codable {
    let calendarApiConnectivity: String?
    
    enum CodingKeys: String, CodingKey {
        case calendarApiConnectivity = "calendar_api_connectivity"
    }
}

// MARK: - Calendar Health Response
struct CalendarHealthResponse: Codable {
    let healthy: Bool
    let service: String
    let timestamp: String
    let googleCalendarApi: HealthStatus
    let oauthTokens: HealthStatus
    let databaseConnectivity: HealthStatus
    let supportedOperations: [String]
    let apiVersion: String
    let issuesFound: [String]
    let recommendations: [String]
    
    enum CodingKeys: String, CodingKey {
        case healthy
        case service
        case timestamp
        case googleCalendarApi = "google_calendar_api"
        case oauthTokens = "oauth_tokens"
        case databaseConnectivity = "database_connectivity"
        case supportedOperations = "supported_operations"
        case apiVersion = "api_version"
        case issuesFound = "issues_found"
        case recommendations
    }
}

// MARK: - Health Status
struct HealthStatus: Codable {
    let healthy: Bool
    let connectivity: String?
    let systemOperational: Bool?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case healthy
        case connectivity
        case systemOperational = "system_operational"
        case status
    }
}

// MARK: - Calendar Events Response (fixed totalCount to optional)
struct CalendarEventsResponse: Codable {
    let events: [CalendarEvent]
    let totalCount: Int?               // made optional to avoid keyNotFound crash
    let timeRange: CalendarTimeRange?
    let calendarsQueried: [String]?
    let hasMore: Bool?
    
    enum CodingKeys: String, CodingKey {
        case events
        case totalCount = "total_count"
        case timeRange = "time_range"
        case calendarsQueried = "calendars_queried"
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
    let primaryCalendar: Calendar?
    let writableCalendars: Int?
    
    enum CodingKeys: String, CodingKey {
        case calendars
        case totalCount = "total_count"
        case primaryCalendar = "primary_calendar"
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

// MARK: - Create Event Request
struct CreateEventRequest: Codable {
    let summary: String
    let startTime: String
    let endTime: String
    let description: String?
    let location: String?
    let calendarId: String?
    let attendees: [String]?
    let timezone: String?
    
    enum CodingKeys: String, CodingKey {
        case summary
        case startTime = "start_time"
        case endTime = "end_time"
        case description
        case location
        case calendarId = "calendar_id"
        case attendees
        case timezone
    }
}

// MARK: - Create Event Response
struct CreateEventResponse: Codable {
    let success: Bool
    let event: CalendarEvent
    let message: String
    let calendarId: String
    let googleEventLink: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case event
        case message
        case calendarId = "calendar_id"
        case googleEventLink = "google_event_link"
    }
}

// MARK: - Availability Check Request
struct AvailabilityCheckRequest: Codable {
    let startTime: String
    let endTime: String
    let calendarIds: [String]?
    
    enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case endTime = "end_time"
        case calendarIds = "calendar_ids"
    }
}

// MARK: - Availability Response
struct AvailabilityResponse: Codable {
    let isFree: Bool
    let timeRange: CalendarTimeRange
    let busyPeriods: [BusyPeriod]
    let calendarsChecked: [String: String]
    let totalConflicts: Int
    let recommendations: [String]
    
    enum CodingKeys: String, CodingKey {
        case isFree = "is_free"
        case timeRange = "time_range"
        case busyPeriods = "busy_periods"
        case calendarsChecked = "calendars_checked"
        case totalConflicts = "total_conflicts"
        case recommendations
    }
}

// MARK: - Busy Period
struct BusyPeriod: Codable {
    let start: String
    let end: String
    let eventId: String?
    
    enum CodingKeys: String, CodingKey {
        case start
        case end
        case eventId = "event_id"
    }
}
