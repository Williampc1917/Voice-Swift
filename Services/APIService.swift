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
    func getGmailStatus(accessToken: String) async throws -> GmailStatusResponse {
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
    
    /// Get recent Gmail messages
    func getGmailMessages(
        accessToken: String,
        maxResults: Int = 10,
        onlyUnread: Bool = false
    ) async throws -> GmailMessagesResponse {
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
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1,
                                   String(data: data, encoding: .utf8) ?? "")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GmailMessagesResponse.self, from: data)
    }
    
    // MARK: - Calendar Methods
    
    /// Check Calendar connection status
    func getCalendarStatus(accessToken: String) async throws -> CalendarStatusResponse {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("calendar/status"))
        req.httpMethod = "GET"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1,
                                   String(data: data, encoding: .utf8) ?? "")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(CalendarStatusResponse.self, from: data)
    }
    
    /// Get upcoming calendar events
    func getCalendarEvents(
        accessToken: String,
        hoursAhead: Int = 24,
        maxEvents: Int = 10,
        includeAllDay: Bool = true
    ) async throws -> CalendarEventsResponse {
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
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1,
                                   String(data: data, encoding: .utf8) ?? "")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(CalendarEventsResponse.self, from: data)
    }
}
