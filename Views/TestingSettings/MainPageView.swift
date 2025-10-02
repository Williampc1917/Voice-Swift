//
//  MainPageView.swift
//  voice-gmail-assistant
//
//  Mission Control - Enhanced with better UX patterns
//

import SwiftUI
import Foundation

struct MainPageView: View {
    @State private var showingSettings = false
    @State private var showingVoiceChat = false
    @State private var safeTop: CGFloat = 0
    
    // App state - PRIVACY: Only metadata, no email content parsing
    @State private var voiceMinutesRemaining = 23
    @State private var unreadEmails = 7
    @State private var starredEmails = 2
    
    // Gmail's own categories (metadata only)
    @State private var primaryEmails = 3
    @State private var socialEmails = 2
    @State private var promotionsEmails = 2
    
    // Priority hints (metadata only)
    @State private var vipEmails = 1
    @State private var ongoingThreads = 2
    
    @State private var todaysMeetings = 3
    @State private var nextMeetingTime = "9:00 AM"
    @State private var nextMeetingTitle = "Team Standup"
    @State private var gmailConnected = true
    @State private var calendarConnected = true
    @State private var draftingStyle = "Professional"
    
    // Last session data
    @State private var lastSessionEmailsHandled = 5
    @State private var lastSessionMeetingsScheduled = 2
    @State private var lastSessionTime = "2h ago"
    
    // UI state
    @State private var recentActivityExpanded = false
    @State private var voiceButtonScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea(.all)
                
                GeometryReader { proxy in
                    Color.clear.preference(key: MainPageSafeTopKey.self, value: proxy.safeAreaInsets.top)
                }
                .frame(height: 0)
                .onPreferenceChange(MainPageSafeTopKey.self) { safeTop = $0 }
                
                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: Header
                        headerSection
                            .padding(.horizontal, 24)
                            .padding(.top, safeTop + 8)
                        
                        // MARK: Last Session Summary
                        if lastSessionEmailsHandled > 0 {
                            lastSessionSection
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                        }
                        
                        // MARK: Hero Voice Button
                        heroVoiceSection
                            .padding(.top, 32)
                        
                        // MARK: Quick Start Options
                        quickActionsSection
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        
                        // MARK: What's Waiting (Metadata Only)
                        whatsWaitingSection
                            .padding(.horizontal, 24)
                            .padding(.top, 32)
                        
                        // MARK: Recent Activity
                        recentActivitySection
                            .padding(.horizontal, 24)
                            .padding(.top, 32)
                        
                        Color.clear.frame(height: 60)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showingVoiceChat) {
                VoiceChatView2()
            }
            .onAppear {
                startGlowAnimation()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(currentGreeting)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("William")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Date and Settings
            HStack(spacing: 16) {
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    // MARK: - Last Session Summary
    private var lastSessionSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Last session (\(lastSessionTime))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text("\(lastSessionEmailsHandled) emails handled • \(lastSessionMeetingsScheduled) meetings scheduled")
                    .font(.callout.weight(.medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.green.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Hero Voice Section
    private var heroVoiceSection: some View {
        VStack(spacing: 20) {
            // Voice Button
            Button {
                if voiceMinutesRemaining > 0 && gmailConnected {
                    showingVoiceChat = true
                }
            } label: {
                ZStack {
                    // Glow rings
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(glowOpacity),
                                    Color.blue.opacity(0)
                                ],
                                center: .center,
                                startRadius: 60,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    // Main button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: Color.blue.opacity(0.4), radius: 20, y: 8)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
                        )
                        .scaleEffect(voiceButtonScale)
                    
                    // Icon
                    Image(systemName: "waveform")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(voiceMinutesRemaining <= 0 || !gmailConnected)
            .opacity(voiceMinutesRemaining <= 0 || !gmailConnected ? 0.5 : 1.0)
            
            // Button label - Simple and inviting
            VStack(spacing: 8) {
                Text("Let's Begin")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                
                // Privacy badge
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption)
                        .foregroundColor(.green.opacity(0.7))
                    
                    Text("Privacy-first • Voice ready")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Error states only
                if !gmailConnected {
                    Text("Connect Gmail to get started")
                        .font(.subheadline)
                        .foregroundColor(.orange.opacity(0.9))
                        .padding(.top, 4)
                } else if voiceMinutesRemaining <= 0 {
                    Text("No voice minutes remaining")
                        .font(.subheadline)
                        .foregroundColor(.orange.opacity(0.9))
                        .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Quick Start Options
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Or start with:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
            
            HStack(spacing: 12) {
                QuickStartButton(
                    icon: "exclamationmark.circle.fill",
                    title: "What's urgent?",
                    color: .red
                ) {
                    // Start voice with urgent filter
                    if voiceMinutesRemaining > 0 && gmailConnected {
                        showingVoiceChat = true
                    }
                }
                
                QuickStartButton(
                    icon: "calendar.circle.fill",
                    title: "What's my day?",
                    color: .blue
                ) {
                    // Start voice with calendar focus
                    if voiceMinutesRemaining > 0 && gmailConnected {
                        showingVoiceChat = true
                    }
                }
                
                QuickStartButton(
                    icon: "sparkles",
                    title: "something",
                    color: .purple
                ) {
                    // Start voice with summary mode
                    if voiceMinutesRemaining > 0 && gmailConnected {
                        showingVoiceChat = true
                    }
                }
            }
        }
    }
    
    // MARK: - What's Waiting Section (Privacy-Safe Metadata)
    private var whatsWaitingSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("What's Waiting")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Email Summary - Using Gmail's Categories + Priority Hints
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        Text("\(unreadEmails) unread emails")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    // Priority hints (metadata only)
                    if vipEmails > 0 || ongoingThreads > 0 {
                        VStack(spacing: 8) {
                            if vipEmails > 0 {
                                CategoryRow(
                                    icon: "star.circle.fill",
                                    color: .yellow,
                                    text: "\(vipEmails) from VIP contacts"
                                )
                            }
                            
                            if ongoingThreads > 0 {
                                CategoryRow(
                                    icon: "arrow.left.arrow.right.circle.fill",
                                    color: .orange,
                                    text: "\(ongoingThreads) ongoing conversations"
                                )
                            }
                        }
                        .padding(.leading, 8)
                    }
                    
                    // Gmail's own categories (no content parsing)
                    if unreadEmails > 0 {
                        VStack(spacing: 8) {
                            if primaryEmails > 0 {
                                CategoryRow(
                                    icon: "person.circle.fill",
                                    color: .blue,
                                    text: "\(primaryEmails) in Primary"
                                )
                            }
                            
                            if socialEmails > 0 {
                                CategoryRow(
                                    icon: "person.2.fill",
                                    color: .purple,
                                    text: "\(socialEmails) in Social"
                                )
                            }
                            
                            if promotionsEmails > 0 {
                                CategoryRow(
                                    icon: "tag.fill",
                                    color: .green,
                                    text: "\(promotionsEmails) in Promotions"
                                )
                            }
                        }
                        .padding(.leading, 8)
                    }
                    
                    // Starred emails (metadata only)
                    if starredEmails > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text("\(starredEmails) starred messages")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.leading, 8)
                        .padding(.top, 4)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Calendar Summary
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        Text("\(todaysMeetings) meetings today")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    if todaysMeetings > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.green.opacity(0.8))
                                .font(.caption)
                            
                            Text("Next: \(nextMeetingTitle) (\(nextMeetingTime))")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.leading, 8)
                    }
                }
                
                // Voice Minutes - Only show if running low
                if voiceMinutesRemaining <= 15 {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        
                        Text("\(voiceMinutesRemaining) voice minutes remaining")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Upgrade") {
                            showingSettings = true
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    recentActivityExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Recent Activity")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: recentActivityExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .buttonStyle(.plain)
            
            if recentActivityExpanded {
                VStack(spacing: 12) {
                    ActivityItem(
                        icon: "paperplane.fill",
                        iconColor: .green,
                        title: "Sent email to Marketing Team",
                        subtitle: "Via voice session",
                        time: "5m ago"
                    )
                    
                    ActivityItem(
                        icon: "calendar.badge.plus",
                        iconColor: .blue,
                        title: "Scheduled meeting with Sarah",
                        subtitle: "Tomorrow at 2:00 PM",
                        time: "12m ago"
                    )
                    
                    ActivityItem(
                        icon: "archivebox.fill",
                        iconColor: .orange,
                        title: "Archived 3 emails",
                        subtitle: "Promotional messages",
                        time: "1h ago"
                    )
                    
                    ActivityItem(
                        icon: "doc.text.fill",
                        iconColor: .purple,
                        title: "Drafted reply",
                        subtitle: "Saved for review",
                        time: "2h ago"
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Helper Properties
    private var currentGreeting: String {
        let hour = NSCalendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Animations
    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            voiceButtonScale = 1.05
        }
    }
}

// MARK: - Supporting Views

private struct MainPageSafeTopKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct QuickStartButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 24, weight: .medium))
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct CategoryRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 16)
            
            Text(text)
                .font(.callout)
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

struct ActivityItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

#Preview {
    MainPageView()
}
