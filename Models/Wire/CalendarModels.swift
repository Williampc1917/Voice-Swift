//
//  CalendarModels.swift
//  voice-gmail-assistant
//
//  Calendar API Response Models
//

import Foundation

// MARK: - Calendar Status Response (NO CodingKeys - relies on convertFromSnakeCase)
struct CalendarStatusResponse: Codable {
    let connected: Bool
    let calendarsAccessible: Int?
    let primaryCalendarAvailable: Bool?
    let canCreateEvents: Bool?
    let connectionHealth: String?
    let healthDetails: CalendarHealthDetails?
    let expiresAt: String?
    let needsRefresh: Bool?
}

// MARK: - Calendar Health Details
struct CalendarHealthDetails: Codable {
    let calendarApiConnectivity: String?
    let status: String?
    let message: String?
    let severity: String?
    let actionRequired: String?
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
}


// MARK: - Health Status
struct HealthStatus: Codable {
    let healthy: Bool
    let connectivity: String?
    let systemOperational: Bool?
    let status: String?
}

// MARK: - Calendar Events Response (NO CodingKeys - relies on convertFromSnakeCase)
struct CalendarEventsResponse: Codable {
    let events: [CalendarEvent]
    let totalCount: Int?
    let timeRange: CalendarTimeRange?
    let calendarsQueried: [String]?
    let hasMore: Bool?
}

// MARK: - Calendar Event (NO CodingKeys - relies on convertFromSnakeCase)
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
}

// MARK: - Calendar Time Range (NO CodingKeys - relies on convertFromSnakeCase)
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
}

// MARK: - Calendar
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
}

// MARK: - Create Event Request (NO CodingKeys - relies on convertFromSnakeCase)
struct CreateEventRequest: Codable {
    let summary: String
    let startTime: String
    let endTime: String
    let description: String?
    let location: String?
    let calendarId: String?
    let attendees: [String]?
    let timezone: String?
}

// MARK: - Create Event Response
struct CreateEventResponse: Codable {
    let success: Bool
    let event: CalendarEvent
    let message: String
    let calendarId: String
    let googleEventLink: String?
}

// MARK: - Availability Check Request (NO CodingKeys - relies on convertFromSnakeCase)
struct AvailabilityCheckRequest: Codable {
    let startTime: String
    let endTime: String
    let calendarIds: [String]?
}

// MARK: - Availability Response (NO CodingKeys - relies on convertFromSnakeCase)
struct AvailabilityResponse: Codable {
    let isFree: Bool
    let timeRange: CalendarTimeRange
    let busyPeriods: [BusyPeriod]
    let calendarsChecked: [String: String]
    let totalConflicts: Int
    let recommendations: [String]
}

// MARK: - Busy Period (NO CodingKeys - relies on convertFromSnakeCase)
struct BusyPeriod: Codable {
    let start: String
    let end: String
    let eventId: String?
}
