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

// MARK: - Email Style Endpoints
// Add this extension to the bottom of your existing APIService.swift file

extension APIService {
    
    /// Get email style options and current status
    /// GET /onboarding/email-style
    func getEmailStyleOptions(accessToken: String) async throws -> EmailStyleStatusResponse {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("onboarding/email-style"))
        req.httpMethod = "GET"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        print("📧 [EMAIL_STYLE] Fetching email style options...")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError.badStatus(-1, "No HTTP response")
        }
        
        print("📧 [EMAIL_STYLE] Response Status: \(http.statusCode)")
        
        // Log raw JSON (truncated for debugging)
        let rawJSON = String(data: data, encoding: .utf8) ?? ""
        print("📧 [EMAIL_STYLE] Raw JSON (first 300 chars): \(String(rawJSON.prefix(300)))")
        
        guard (200...299).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            print("❌ [EMAIL_STYLE] Error \(http.statusCode): \(String(errorBody.prefix(200)))")
            throw APIError.badStatus(http.statusCode, errorBody)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let response = try decoder.decode(EmailStyleStatusResponse.self, from: data)
            
            // Log parsed response
            print("✅ [EMAIL_STYLE] Email Style Status:")
            print("✅ [EMAIL_STYLE] - currentStep: \(response.currentStep)")
            print("✅ [EMAIL_STYLE] - styleSelected: \(response.styleSelected ?? "none")")
            print("✅ [EMAIL_STYLE] - availableOptions: \(response.availableOptions.count)")
            print("✅ [EMAIL_STYLE] - canAdvance: \(response.canAdvance)")
            
            // Log each option
            for (index, option) in response.availableOptions.enumerated() {
                print("✅ [EMAIL_STYLE] Option #\(index + 1):")
                print("✅ [EMAIL_STYLE]   - name: \(option.name)")
                print("✅ [EMAIL_STYLE]   - available: \(option.available)")
                if let rateLimit = option.rateLimitInfo {
                    print("✅ [EMAIL_STYLE]   - canExtract: \(rateLimit.canExtract)")
                    print("✅ [EMAIL_STYLE]   - used: \(rateLimit.usedToday)/\(rateLimit.dailyLimit)")
                }
            }
            
            return response
        } catch {
            print("❌ [EMAIL_STYLE] Parsing error: \(error)")
            throw APIError.decoding("Email style options parsing failed: \(error.localizedDescription)")
        }
    }
    
    /// Select a predefined email style (Casual or Professional)
    /// PUT /onboarding/email-style
    func selectPredefinedEmailStyle(
        accessToken: String,
        styleType: String
    ) async throws -> EmailStyleSelectionResponse {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("onboarding/email-style"))
        req.httpMethod = "PUT"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["style_type": styleType]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📧 [EMAIL_STYLE] Selecting predefined style: \(styleType)")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError.badStatus(-1, "No HTTP response")
        }
        
        print("📧 [EMAIL_STYLE] Response Status: \(http.statusCode)")
        
        // Log raw JSON
        let rawJSON = String(data: data, encoding: .utf8) ?? ""
        print("📧 [EMAIL_STYLE] Raw JSON: \(String(rawJSON.prefix(300)))")
        
        guard (200...299).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            print("❌ [EMAIL_STYLE] Error \(http.statusCode): \(errorBody)")
            
            // Handle specific error cases
            if http.statusCode == 400 {
                if errorBody.contains("not on email_style step") {
                    throw APIError.badStatus(http.statusCode, "Not on email style step. Please complete previous steps first.")
                }
            }
            
            throw APIError.badStatus(http.statusCode, errorBody)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let response = try decoder.decode(EmailStyleSelectionResponse.self, from: data)
            
            // Log parsed response
            print("✅ [EMAIL_STYLE] Style selected successfully:")
            print("✅ [EMAIL_STYLE] - styleType: \(response.styleType)")
            print("✅ [EMAIL_STYLE] - nextStep: \(response.nextStep)")
            print("✅ [EMAIL_STYLE] - message: \(response.message)")
            
            return response
        } catch {
            print("❌ [EMAIL_STYLE] Parsing error: \(error)")
            throw APIError.decoding("Email style selection parsing failed: \(error.localizedDescription)")
        }
    }
    
    /// Create a custom email style from user examples
    /// POST /onboarding/email-style/custom
    func createCustomEmailStyle(
        accessToken: String,
        emailExamples: [String]
    ) async throws -> CustomEmailStyleResponse {
        var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("onboarding/email-style/custom"))
        req.httpMethod = "POST"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email_examples": emailExamples]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📧 [EMAIL_STYLE] Creating custom style with \(emailExamples.count) examples...")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError.badStatus(-1, "No HTTP response")
        }
        
        print("📧 [EMAIL_STYLE] Response Status: \(http.statusCode)")
        
        // Log raw JSON
        let rawJSON = String(data: data, encoding: .utf8) ?? ""
        print("📧 [EMAIL_STYLE] Raw JSON (first 500 chars): \(String(rawJSON.prefix(500)))")
        
        // Note: This endpoint can return 200 even on failure (with success: false)
        // So we need to check the response body, not just status code
        guard (200...299).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            print("❌ [EMAIL_STYLE] Error \(http.statusCode): \(errorBody)")
            
            // Handle specific error cases
            if http.statusCode == 400 {
                if errorBody.contains("not on email_style step") {
                    throw APIError.badStatus(http.statusCode, "Not on email style step. Please complete previous steps first.")
                }
            }
            
            throw APIError.badStatus(http.statusCode, errorBody)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let response = try decoder.decode(CustomEmailStyleResponse.self, from: data)
            
            // Log parsed response
            print("✅ [EMAIL_STYLE] Custom style response:")
            print("✅ [EMAIL_STYLE] - success: \(response.success)")
            
            if response.success {
                print("✅ [EMAIL_STYLE] - extractionGrade: \(response.extractionGrade ?? "none")")
                print("✅ [EMAIL_STYLE] - nextStep: \(response.nextStep ?? "none")")
                
                if let profile = response.styleProfile {
                    print("✅ [EMAIL_STYLE] - greeting style: \(profile.greeting.style)")
                    print("✅ [EMAIL_STYLE] - closing styles: \(profile.closing.styles.joined(separator: ", "))")
                    print("✅ [EMAIL_STYLE] - formality: \(profile.tone.formality)/5")
                }
            } else {
                print("❌ [EMAIL_STYLE] - error: \(response.errorMessage ?? "unknown error")")
                
                if let rateLimitInfo = response.rateLimitInfo {
                    print("❌ [EMAIL_STYLE] - rate limit: \(rateLimitInfo.used)/\(rateLimitInfo.limit)")
                    print("❌ [EMAIL_STYLE] - resets at: \(rateLimitInfo.resetTime)")
                }
            }
            
            return response
        } catch {
            print("❌ [EMAIL_STYLE] Parsing error: \(error)")
            throw APIError.decoding("Custom email style parsing failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Helper Types for Better API Ergonomics

extension APIService {
    /// Convenience enum for predefined style types
    enum PredefinedEmailStyle: String {
        case casual = "casual"
        case professional = "professional"
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    /// Type-safe wrapper for selecting predefined styles
    func selectEmailStyle(
        accessToken: String,
        style: PredefinedEmailStyle
    ) async throws -> EmailStyleSelectionResponse {
        try await selectPredefinedEmailStyle(
            accessToken: accessToken,
            styleType: style.rawValue
        )
    }
}
