//
//  GmailCalendarTestView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/20/25.
//

import SwiftUI

struct GmailCalendarTestView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var testManager = GmailCalendarTestManager()
    
    var body: some View {
        ZStack {
            AppBackground()
            
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
                        SectionHeader(title: "Gmail", icon: "envelope", isLoading: testManager.isLoadingGmail)
                        
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
                        SectionHeader(title: "Calendar", icon: "calendar", isLoading: testManager.isLoadingCalendar)
                        
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
        .task {
            await testManager.loadInitialData()
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    let isLoading: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
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

// MARK: - Email Card
struct EmailCard: View {
    let email: MockEmail
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Always visible header
            HStack {
                Text(email.sender)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                Spacer()
                Text(email.time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                // Expand/collapse indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
            }
            
            Text(email.subject)
                .font(.callout)
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(isExpanded ? nil : 2)
            
            Text(email.preview)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(isExpanded ? nil : 2)
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Full email content
                    Text(email.fullContent)
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Email metadata
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("To:")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text(email.recipient)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        HStack {
                            Text("Labels:")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack(spacing: 4) {
                                ForEach(email.labels, id: \.self) { label in
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
                        
                        if !email.attachments.isEmpty {
                            HStack {
                                Text("Attachments:")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(email.attachments.count) files")
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
                if email.isUnread {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                    Text("Unread")
                        .font(.caption2)
                        .foregroundColor(.blue)
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

// MARK: - Event Card
struct EventCard: View {
    let event: MockEvent
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Always visible header
            HStack {
                Text(event.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                Spacer()
                Text(event.date)
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
                Text(event.time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if !event.location.isEmpty {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                    Text(event.location)
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
                    if !event.description.isEmpty {
                        Text(event.description)
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Attendees list
                    if !event.attendees.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Attendees:")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            ForEach(event.attendees, id: \.self) { attendee in
                                HStack {
                                    Image(systemName: "person.circle")
                                        .foregroundColor(.white.opacity(0.4))
                                        .font(.caption)
                                    Text(attendee)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                    
                    // Meeting link
                    if !event.meetingLink.isEmpty {
                        HStack {
                            Image(systemName: "video")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Join Meeting")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    // Event metadata
                    HStack {
                        Text("Created by:")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text(event.organizer)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
            
            HStack {
                if !event.attendees.isEmpty && !isExpanded {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption)
                        Text("\(event.attendees.count) attendees")
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

// MARK: - Mock Data Models
struct MockEmail: Identifiable {
    let id = UUID()
    let sender: String
    let subject: String
    let preview: String
    let fullContent: String
    let recipient: String
    let time: String
    let isUnread: Bool
    let labels: [String]
    let attachments: [String]
}

struct MockEvent: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: String
    let time: String
    let location: String
    let attendees: [String]
    let organizer: String
    let meetingLink: String
}

// MARK: - Test Manager
@MainActor
class GmailCalendarTestManager: ObservableObject {
    @Published var recentEmails: [MockEmail] = []
    @Published var upcomingEvents: [MockEvent] = []
    @Published var isLoadingGmail = false
    @Published var isLoadingCalendar = false
    @Published var gmailError: String?
    @Published var calendarError: String?
    
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
    
    private func loadGmailData() async {
        isLoadingGmail = true
        gmailError = nil
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Mock data - replace with actual API calls
        recentEmails = [
            MockEmail(
                sender: "GitHub",
                subject: "New pull request opened",
                preview: "A new pull request has been opened for voice-gmail-assistant repository...",
                fullContent: "Hi there! A new pull request #42 has been opened by @contributor123 for the voice-gmail-assistant repository. The PR includes improvements to the OnboardingProfileView styling and adds new animation features. Please review the changes and provide feedback. The automated tests are passing and the code coverage remains at 85%.",
                recipient: "william@company.com",
                time: "2 min ago",
                isUnread: true,
                labels: ["Work", "GitHub", "Important"],
                attachments: ["PR_Details.pdf"]
            ),
            MockEmail(
                sender: "Apple Developer",
                subject: "App Store Connect Weekly Summary",
                preview: "Here's your weekly summary of app performance and user engagement...",
                fullContent: "Your apps had 1,247 downloads this week, with the voice-gmail-assistant beta receiving particularly positive feedback. User retention is up 15% compared to last week. The latest build has been approved for TestFlight distribution. Three new crash reports have been submitted - please review them in the crash analytics section.",
                recipient: "william@company.com",
                time: "1 hour ago",
                isUnread: false,
                labels: ["App Store", "Analytics"],
                attachments: []
            ),
            MockEmail(
                sender: "Claude AI",
                subject: "Welcome to Claude Pro",
                preview: "Thanks for upgrading to Claude Pro! Here's what you can expect...",
                fullContent: "Welcome to Claude Pro! You now have access to priority bandwidth, extended usage limits, and early access to new features. Your subscription includes unlimited conversations during peak hours and access to our most capable models. We're excited to see what you build with these enhanced capabilities.",
                recipient: "william@company.com",
                time: "3 hours ago",
                isUnread: true,
                labels: ["Claude", "Subscription"],
                attachments: ["Getting_Started_Guide.pdf", "Feature_Overview.pdf"]
            )
        ]
        
        isLoadingGmail = false
    }
    
    private func loadCalendarData() async {
        isLoadingCalendar = true
        calendarError = nil
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Mock data - replace with actual API calls
        upcomingEvents = [
            MockEvent(
                title: "Team Standup",
                description: "Daily standup meeting to discuss progress, blockers, and plan for the day. Please come prepared with your updates on yesterday's work and today's priorities.",
                date: "Today",
                time: "10:00 AM - 10:30 AM",
                location: "Conference Room A, 2nd Floor",
                attendees: ["alice@company.com", "bob@company.com", "charlie@company.com"],
                organizer: "alice@company.com",
                meetingLink: "https://zoom.us/j/123456789"
            ),
            MockEvent(
                title: "Voice Assistant Demo",
                description: "Demonstration of the new voice assistant features to stakeholders. We'll showcase the Gmail integration, calendar management, and voice command capabilities. Please prepare the demo environment beforehand.",
                date: "Tomorrow",
                time: "2:00 PM - 3:00 PM",
                location: "Main Conference Room, Executive Floor",
                attendees: ["stakeholder1@company.com", "stakeholder2@company.com", "ceo@company.com", "william@company.com"],
                organizer: "william@company.com",
                meetingLink: "https://zoom.us/j/987654321"
            ),
            MockEvent(
                title: "Code Review Session",
                description: "Weekly code review session focusing on the OnboardingProfileView refactoring and new design system implementation.",
                date: "Friday",
                time: "4:00 PM - 5:00 PM",
                location: "Development Team Room",
                attendees: ["dev1@company.com", "dev2@company.com"],
                organizer: "dev1@company.com",
                meetingLink: ""
            )
        ]
        
        isLoadingCalendar = false
    }
}

#Preview {
    GmailCalendarTestView()
        .environmentObject(AuthManager())
}
