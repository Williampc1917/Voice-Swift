//
//  GmailCalendarTestView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/20/25.
// working with actual api 

import SwiftUI

struct GmailCalendarTestView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var testManager = GmailCalendarTestManager()
    
    var body: some View {
        ZStack {
            // Background that extends to all edges including safe areas
            AppBackground()
                .ignoresSafeArea(.all) // This ensures the background covers everything
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "flask")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.blue)
                            
                            Text("Service Test")
                                .font(.title.bold())
                                .foregroundColor(.white)
                        }
                        
                        Text("Testing Gmail and Calendar integration")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.top, 20)
                    
                    // Gmail Section
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Gmail",
                            icon: "envelope",
                            isLoading: testManager.isLoadingGmail,
                            isConnected: testManager.gmailConnected
                        )
                        
                        if testManager.gmailError != nil {
                            ErrorCard(message: testManager.gmailError!)
                        } else if testManager.recentEmails.isEmpty && !testManager.isLoadingGmail {
                            EmptyStateCard(message: "No recent emails found")
                        } else {
                            ForEach(testManager.recentEmails) { email in
                                EmailCard(email: email)
                            }
                        }
                    }
                    
                    // Calendar Section
                    VStack(spacing: 16) {
                        SectionHeader(
                            title: "Calendar",
                            icon: "calendar",
                            isLoading: testManager.isLoadingCalendar,
                            isConnected: testManager.calendarConnected
                        )
                        
                        if testManager.calendarError != nil {
                            ErrorCard(message: testManager.calendarError!)
                        } else if testManager.upcomingEvents.isEmpty && !testManager.isLoadingCalendar {
                            EmptyStateCard(message: "No upcoming events found")
                        } else {
                            ForEach(testManager.upcomingEvents) { event in
                                EventCard(event: event)
                            }
                        }
                    }
                    
                    // Refresh Button
                    Button {
                        Task {
                            await testManager.refreshData()
                        }
                    } label: {
                        Label("Refresh Data", systemImage: "arrow.clockwise")
                    }
                    .appButtonStyle(disabled: testManager.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 44)
                }
                .padding(.horizontal, 24)
            }
            
            
        }
        
        .background {
            AppBackground()
                .ignoresSafeArea()
        }
        .task {
            await testManager.loadInitialData()
        }
    }
}

// MARK: - Section Header with Connection Status
struct SectionHeader: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let isConnected: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Connection status indicator
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.blue)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Email Card (Updated for Real API Data)
struct EmailCard: View {
    let email: GmailMessage
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Always visible header
            HStack {
                Text(email.sender.name ?? email.sender.email)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                Spacer()
                Text(email.ageDescription ?? "Unknown time")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                // Expand/collapse indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
            }
            
            Text(email.subject ?? "No Subject")
                .font(.callout)
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(isExpanded ? nil : 2)
            
            Text(email.snippet ?? "")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(isExpanded ? nil : 2)
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Full email content
                    if let bodyText = email.bodyText, !bodyText.isEmpty {
                        // Prefer plain text if available
                        LinkifiedText(text: bodyText)
                    } else if let html = email.bodyHtml, !html.isEmpty {
                        // Just dump raw HTML as plain text for now, lazyyyyyyyyyy
                        ScrollView(.horizontal) {
                            Text(html)
                                .font(.caption2.monospaced())
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.vertical, 4)
                        }
                    }
                    
                    // Email metadata
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("From:")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text(email.sender.email)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        if let labels = email.labels, !labels.isEmpty {
                            HStack {
                                Text("Labels:")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                HStack(spacing: 4) {
                                    ForEach(labels.prefix(3), id: \.self) { label in
                                        Text(label)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.3))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        
                        if email.hasAttachments == true {
                            HStack {
                                Text("Has attachments")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Image(systemName: "paperclip")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
            
            HStack {
                if email.isUnread == true {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                    Text("Unread")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                if email.isStarred == true {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                if !isExpanded {
                    Text("Tap to expand")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .appCardStyle()
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Event Card (Updated for Real API Data)
struct EventCard: View {
    let event: CalendarEvent
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Always visible header
            HStack {
                Text(event.summary ?? "No Title")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                Spacer()
                Text(formatEventDate(event.startTime))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                // Expand/collapse indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
                Text(formatEventTime(event.startTime, event.endTime, event.isAllDay))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if let location = event.location, !location.isEmpty {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(isExpanded ? nil : 1)
                }
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Event description
                    if let description = event.description, !description.isEmpty {
                        Text(description)
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Event metadata
                    VStack(alignment: .leading, spacing: 4) {
                        if let status = event.status {
                            HStack {
                                Text("Status:")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.white.opacity(0.6))
                                Text(status.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        if let attendeesCount = event.attendeesCount, attendeesCount > 0 {
                            HStack {
                                Text("Attendees:")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(attendeesCount) people")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        if let timezone = event.timezone {
                            HStack {
                                Text("Timezone:")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.white.opacity(0.6))
                                Text(timezone)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
            
            HStack {
                if event.isAllDay == true {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption)
                        Text("All day")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                Spacer()
                
                if !isExpanded {
                    Text("Tap to expand")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .appCardStyle()
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }
    }
    
    // Helper functions for date/time formatting
    private func formatEventDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "Unknown date" }
        // Simple parsing - you can enhance this
        if let date = ISO8601DateFormatter().date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
        return "Unknown date"
    }
    
    private func formatEventTime(_ startString: String?, _ endString: String?, _ isAllDay: Bool?) -> String {
        if isAllDay == true {
            return "All day"
        }
        
        guard let startString = startString else { return "Unknown time" }
        
        if let startDate = ISO8601DateFormatter().date(from: startString) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            var result = formatter.string(from: startDate)
            
            if let endString = endString,
               let endDate = ISO8601DateFormatter().date(from: endString) {
                result += " - " + formatter.string(from: endDate)
            }
            
            return result
        }
        
        return "Unknown time"
    }
}

// MARK: - Error Card
struct ErrorCard: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.callout)
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
        .appCardStyle()
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "tray")
                .foregroundColor(.white.opacity(0.4))
            Text(message)
                .font(.callout)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
        }
        .appCardStyle()
    }
}

// MARK: - Updated Test Manager with Real API Calls
@MainActor
class GmailCalendarTestManager: ObservableObject {
    @Published var recentEmails: [GmailMessage] = []
    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var isLoadingGmail = false
    @Published var isLoadingCalendar = false
    @Published var gmailError: String?
    @Published var calendarError: String?
    
    // Connection status
    @Published var gmailConnected = false
    @Published var calendarConnected = false
    
    private let api = APIService()
    private let supabaseSvc = SupabaseService()
    
    var isLoading: Bool {
        isLoadingGmail || isLoadingCalendar
    }
    
    func loadInitialData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadGmailData() }
            group.addTask { await self.loadCalendarData() }
        }
    }
    
    func refreshData() async {
        await loadInitialData()
    }
    
    // MARK: - Gmail Data Loading
    private func loadGmailData() async {
        isLoadingGmail = true
        gmailError = nil
        recentEmails = []
        
        do {
            // Get access token
            let token = try await supabaseSvc.currentAccessToken()
            
            // Check Gmail connection status first
            let status = try await api.getGmailStatus(accessToken: token)
            gmailConnected = status.connected
            
            if !status.connected {
                gmailError = "Gmail not connected"
                isLoadingGmail = false
                return
            }
            
            // Fetch recent emails (max 5)
            let response = try await api.getGmailMessages(
                accessToken: token,
                maxResults: 5,
                onlyUnread: false
            )
            
            recentEmails = response.messages
            print("✅ Loaded \(recentEmails.count) Gmail messages")
            
        } catch {
            print("❌ Gmail error: \(error)")
            gmailConnected = false
            
            // Simple error messages
            if error.localizedDescription.contains("401") || error.localizedDescription.contains("403") {
                gmailError = "Gmail connection expired"
            } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                gmailError = "Network error"
            } else {
                gmailError = "Failed to load Gmail data"
            }
        }
        
        isLoadingGmail = false
    }
    
    // MARK: - Calendar Data Loading
    private func loadCalendarData() async {
        isLoadingCalendar = true
        calendarError = nil
        upcomingEvents = []
        
        do {
            // Get access token
            let token = try await supabaseSvc.currentAccessToken()
            
            // Check Calendar connection status first
            let status = try await api.getCalendarStatus(accessToken: token)
            calendarConnected = status.connected
            
            if !status.connected {
                calendarError = "Calendar not connected"
                isLoadingCalendar = false
                return
            }
            
            // Fetch upcoming events (max 5, next 24 hours)
            let response = try await api.getCalendarEvents(
                accessToken: token,
                hoursAhead: 24,
                maxEvents: 5,
                includeAllDay: true
            )
            
            upcomingEvents = response.events
            print("✅ Loaded \(upcomingEvents.count) Calendar events")
            
        } catch {
            print("❌ Calendar error: \(error)")
            calendarConnected = false
            
            // Simple error messages
            if error.localizedDescription.contains("401") || error.localizedDescription.contains("403") {
                calendarError = "Calendar connection expired"
            } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                calendarError = "Network error"
            } else {
                calendarError = "Failed to load Calendar data"
            }
        }
        
        isLoadingCalendar = false
    }
}

#Preview {
    GmailCalendarTestView()
        .environmentObject(AuthManager())
}
