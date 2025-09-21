//
//  APIService.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//

import Foundation

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case badStatus(Int, String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case let .badStatus(code, body):
            return "Backend error (\(code)): \(body)"
        case let .decoding(msg):
            return "Failed to read server response: \(msg)"
        }
    }
}

// MARK: - Service
final class APIService {

    // MARK: - User Profile
    func getUserProfile(accessToken: String) async throws -> UserProfile {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("me"))
        req.httpMethod = "GET"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError.badStatus(-1, "No HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.badStatus(http.statusCode, body)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let envelope = try decoder.decode(MeEnvelope.self, from: data)
            let w = envelope.profile
            return UserProfile(
                id: w.userId,
                email: w.email,
                displayName: w.displayName,
                plan: w.plan.name
            )
        } catch {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.decoding(body)
        }
    }
}

// MARK: - Onboarding Endpoints
extension APIService {
    func getOnboardingStatus(accessToken: String) async throws -> WireOnboardingStatus {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("onboarding/status"))
        req.httpMethod = "GET"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1,
                                     String(data: data, encoding: .utf8) ?? "")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WireOnboardingStatus.self, from: data)
    }

    func updateProfileName(
        accessToken: String,
        displayName: String,
        timezone: String
    ) async throws -> WireOnboardingProfileUpdateResponse {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("onboarding/profile"))
        req.httpMethod = "PUT"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue(timezone, forHTTPHeaderField: "X-Timezone")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["display_name": displayName]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1,
                                     String(data: data, encoding: .utf8) ?? "")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WireOnboardingProfileUpdateResponse.self, from: data)
    }
}

// MARK: - Gmail Endpoints
extension APIService {
    /// 1. Start OAuth flow → fetch Gmail auth URL
    func getGmailAuthURL(accessToken: String) async throws -> GmailAuthURLResponse {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("auth/gmail/url"))
        req.httpMethod = "GET"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1,
                                     String(data: data, encoding: .utf8) ?? "")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GmailAuthURLResponse.self, from: data)
    }

    /// 2. Complete OAuth flow → exchange code + state
    func postGmailCallback(
        accessToken: String,
        code: String,
        state: String
    ) async throws -> GmailCallbackResponse {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("auth/gmail/callback"))
        req.httpMethod = "POST"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["code": code, "state": state]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1,
                                     String(data: data, encoding: .utf8) ?? "")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GmailCallbackResponse.self, from: data)
    }

    /// 3. Check Gmail connection status
    func getGmailAuthStatus(accessToken: String) async throws -> GmailStatusResponse {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("auth/gmail/status"))
        req.httpMethod = "GET"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1,
                                     String(data: data, encoding: .utf8) ?? "")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GmailStatusResponse.self, from: data)
    }

    /// 4. Disconnect Gmail account
    func disconnectGmail(accessToken: String) async throws -> GmailDisconnectResponse {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("auth/gmail/disconnect"))
        req.httpMethod = "DELETE"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1,
                                     String(data: data, encoding: .utf8) ?? "")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GmailDisconnectResponse.self, from: data)
    }
}
// MARK: - Gmail OAuth Retrieve (NEW)
extension APIService {
    /// Retrieve OAuth data after Google redirect (step between Safari and final callback)
    func retrieveGmailOAuthData(
        accessToken: String,
        state: String
    ) async throws -> GmailRetrieveResponse {
        var req = URLRequest(
            url: AppConfig.backendBaseURL.appendingPathComponent("auth/gmail/callback/retrieve/\(state)")
        )
        req.httpMethod = "GET"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse else {
            throw APIError.badStatus(-1, "No HTTP response")
        }

        if !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("🔴 retrieveGmailOAuthData ERROR (\(http.statusCode)) → \(body)")
            throw APIError.badStatus(http.statusCode, body)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GmailRetrieveResponse.self, from: data)
    }
}
extension APIService {
    /// Get fresh onboarding status (bypasses any caching/race conditions)
    func getFreshOnboardingStatus(accessToken: String) async throws -> WireOnboardingStatus {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("onboarding/status/fresh"))
        req.httpMethod = "GET"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1,
                                     String(data: data, encoding: .utf8) ?? "")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WireOnboardingStatus.self, from: data)
    }
}
// MARK: - Gmail & Calendar API Extensions
// Add this to the BOTTOM of your existing APIService.swift file
// Make sure you've added GmailModels.swift and CalendarModels.swift files first

// Replace everything after this comment in your APIService.swift:
// MARK: - Gmail & Calendar API Extensions

// Replace everything after this comment in your APIService.swift:
// MARK: - Gmail & Calendar API Extensions

extension APIService {
    
    // MARK: - Gmail Methods
    
    /// Check Gmail connection status
    func getGmailStatus(accessToken: String) async throws -> GmailStatusResponse {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("gmail/status"))
        req.httpMethod = "GET"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1,
                                   String(data: data, encoding: .utf8) ?? "")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GmailStatusResponse.self, from: data)
    }
    
    /// Get recent Gmail messages with clean logging
    func getGmailMessages(
        accessToken: String,
        maxResults: Int = 10,
        onlyUnread: Bool = false
    ) async throws -> GmailMessagesResponse {
        
        print("📧 [GMAIL] Fetching \(maxResults) messages, onlyUnread: \(onlyUnread)")
        
        var urlComponents = URLComponents(url: AppConfig.backendBaseURL.appendingPathComponent("gmail/messages"), resolvingAgainstBaseURL: false)!
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "max_results", value: String(maxResults)))
        if onlyUnread {
            queryItems.append(URLQueryItem(name: "only_unread", value: "true"))
        }
        urlComponents.queryItems = queryItems
        
        var req = URLRequest(url: urlComponents.url!)
        req.httpMethod = "GET"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        print("📧 [GMAIL] Request URL: \(req.url?.absoluteString ?? "")")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? -1
            print("❌ [GMAIL] Error \(statusCode): \(String(errorBody.prefix(200)))")
            throw APIError.badStatus(statusCode, errorBody)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(GmailMessagesResponse.self, from: data)
        
        // Clean logging - no more massive HTML dumps
        print("✅ [GMAIL] Loaded \(response.messages.count) messages")
        print("✅ [GMAIL] Total found: \(response.totalFound ?? -1)")
        
        // Log each message summary (no HTML content)
        for (index, message) in response.messages.enumerated() {
            print("✅ [GMAIL] Message #\(index + 1):")
            print("✅ [GMAIL]   - Subject: \(message.subject ?? "No subject")")
            print("✅ [GMAIL]   - From: \(message.sender.name ?? message.sender.email)")
            print("✅ [GMAIL]   - Snippet: \(String((message.snippet ?? "").prefix(80)))...")
            print("✅ [GMAIL]   - Unread: \(message.isUnread ?? false)")
            print("✅ [GMAIL]   - Labels: \(message.labels?.joined(separator: ", ") ?? "none")")
            
            // Show content sizes instead of dumping HTML
            if let bodyText = message.bodyText {
                print("✅ [GMAIL]   - Body text: \(bodyText.count) chars")
            }
            if let bodyHtml = message.bodyHtml {
                print("✅ [GMAIL]   - Body HTML: \(bodyHtml.count) chars")
            }
        }
        
        return response
    }
    
    // MARK: - Calendar Methods
    
    /// Check Calendar connection status
    func getCalendarStatus(accessToken: String) async throws -> CalendarStatusResponse {
        print("📅 [CALENDAR] Starting calendar status check...")
        
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("calendar/status"))
        req.httpMethod = "GET"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        print("📅 [CALENDAR] Request URL: \(req.url?.absoluteString ?? "")")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError.badStatus(-1, "No HTTP response")
        }
        
        print("📅 [CALENDAR] Response Status: \(http.statusCode)")
        
        // Log raw JSON (truncated)
        let rawJSON = String(data: data, encoding: .utf8) ?? ""
        print("📅 [CALENDAR] Raw JSON (first 300 chars): \(String(rawJSON.prefix(300)))")
        
        guard (200...299).contains(http.statusCode) else {
            throw APIError.badStatus(http.statusCode, rawJSON)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let response = try decoder.decode(CalendarStatusResponse.self, from: data)
            
            // Log parsed response
            print("✅ [CALENDAR] Calendar Status:")
            print("✅ [CALENDAR] - connected: \(response.connected)")
            print("✅ [CALENDAR] - calendarsAccessible: \(response.calendarsAccessible ?? -1)")
            print("✅ [CALENDAR] - canCreateEvents: \(response.canCreateEvents ?? false)")
            
            return response
        } catch {
            print("❌ [CALENDAR] Parsing error: \(error)")
            throw APIError.decoding("Calendar status parsing failed")
        }
    }
    
    /// Get upcoming calendar events
    func getCalendarEvents(
        accessToken: String,
        hoursAhead: Int = 24,
        maxEvents: Int = 10,
        includeAllDay: Bool = true
    ) async throws -> CalendarEventsResponse {
        
        print("📅 [CALENDAR] Fetching events: hoursAhead=\(hoursAhead), maxEvents=\(maxEvents)")
        
        var urlComponents = URLComponents(url: AppConfig.backendBaseURL.appendingPathComponent("calendar/events"), resolvingAgainstBaseURL: false)!
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "hours_ahead", value: String(hoursAhead)))
        queryItems.append(URLQueryItem(name: "max_events", value: String(maxEvents)))
        if includeAllDay {
            queryItems.append(URLQueryItem(name: "include_all_day", value: "true"))
        }
        urlComponents.queryItems = queryItems
        
        var req = URLRequest(url: urlComponents.url!)
        req.httpMethod = "GET"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        print("📅 [CALENDAR] Request URL: \(req.url?.absoluteString ?? "")")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError.badStatus(-1, "No HTTP response")
        }
        
        print("📅 [CALENDAR] Response Status: \(http.statusCode)")
        
        // Log raw JSON (truncated)
        let rawJSON = String(data: data, encoding: .utf8) ?? ""
        print("📅 [CALENDAR] Raw JSON (first 500 chars): \(String(rawJSON.prefix(500)))")
        
        guard (200...299).contains(http.statusCode) else {
            throw APIError.badStatus(http.statusCode, rawJSON)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let response = try decoder.decode(CalendarEventsResponse.self, from: data)
            
            // Log parsed response
            print("✅ [CALENDAR] Events Response:")
            print("✅ [CALENDAR] - events count: \(response.events.count)")
            print("✅ [CALENDAR] - totalCount: \(response.totalCount ?? -1)")
            
            // Log each event
            for (index, event) in response.events.enumerated() {
                print("✅ [CALENDAR] Event #\(index + 1):")
                print("✅ [CALENDAR]   - summary: \(event.summary ?? "nil")")
                print("✅ [CALENDAR]   - startTime: \(event.startTime ?? "nil")")
                print("✅ [CALENDAR]   - endTime: \(event.endTime ?? "nil")")
                print("✅ [CALENDAR]   - location: \(event.location ?? "nil")")
                print("✅ [CALENDAR]   - isAllDay: \(event.isAllDay ?? false)")
                print("✅ [CALENDAR]   - attendeesCount: \(event.attendeesCount ?? 0)")
            }
            
            return response
        } catch {
            print("❌ [CALENDAR] Parsing error: \(error)")
            throw APIError.decoding("Calendar events parsing failed")
        }
    }
}
