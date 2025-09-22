//
//  SettingsView.swift
//  voice-gmail-assistant
//
//  Complete settings view with custom drafting setup
//

import SwiftUI

private struct SettingsSafeTopKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    // State
    @State private var userName = "Jane Doe"
    @State private var draftingStyle = "Professional"
    @State private var voiceModel = "Assistant Voice"
    @State private var subscriptionType = "Free"
    @State private var gmailConnected = true
    @State private var calendarConnected = false
    @State private var isEditingName = false
    @State private var voiceMinutesRemaining = 5 // Mock minutes remaining

    // Custom drafting style states
    @State private var customStyleConfigured = false
    @State private var showingCustomSetup = false

    @State private var safeTop: CGFloat = 0

    let draftingOptions = ["Professional", "Casual", "Custom"]
    let voiceOptions = ["Assistant Voice", "Companion Voice"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground().ignoresSafeArea()

                GeometryReader { proxy in
                    Color.clear.preference(key: SettingsSafeTopKey.self, value: proxy.safeAreaInsets.top)
                }
                .frame(height: 0)
                .onPreferenceChange(SettingsSafeTopKey.self) { safeTop = $0 }

                ScrollView {
                    VStack(spacing: 32) {
                        // MARK: Hero Header
                        VStack(spacing: 8) {
                            HStack {
                                Button("Done") { dismiss() }
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .contentShape(Rectangle())
                                Spacer()
                            }

                            VStack(spacing: 4) {
                                Text("Settings")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Customize your experience")
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.top, 12)

                            Divider()
                                .background(Color.white.opacity(0.15))
                                .padding(.top, 8)
                        }
                        .padding(.top, safeTop + 8)

                        // MARK: Sections
                        profileSection
                        voiceUsageSection
                        draftingStyleSection
                        voiceSection
                        subscriptionSection
                        connectionStatusSection
                        Color.clear.frame(height: 44)
                    }
                    .padding(.horizontal, 24)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingCustomSetup) {
                CustomDraftingSetupView(isConfigured: $customStyleConfigured)
                    .onDisappear {
                        if customStyleConfigured {
                            draftingStyle = "Custom"
                        }
                    }
            }
        }
    }

    // MARK: - Sections
    private var profileSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.circle").foregroundColor(.blue).font(.headline)
                Text("Profile").font(.headline).foregroundColor(.white)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Name").font(.subheadline.weight(.medium)).foregroundColor(.white.opacity(0.85))
                    Spacer()
                    if isEditingName {
                        Button("Save") { isEditingName = false }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.blue)
                    } else {
                        Button("Edit") { isEditingName = true }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                if isEditingName {
                    TextField("Enter your name", text: $userName)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .appInputStyle()
                } else {
                    Text(userName)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appInputStyle()
                }
            }
            .appCardStyle()
        }
    }

    private var voiceUsageSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "timer").foregroundColor(.blue).font(.headline)
                Text("Voice Usage").font(.headline).foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Minutes remaining display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Minutes Remaining")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white.opacity(0.85))
                        
                        HStack(spacing: 8) {
                            Text("\(voiceMinutesRemaining)")
                                .font(.title2.bold())
                                .foregroundColor(voiceMinutesRemaining > 10 ? .white : .orange)
                            
                            Text("min")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    // Visual indicator
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(voiceMinutesRemaining) / 100.0) // Assuming 100 is max
                            .stroke(
                                voiceMinutesRemaining > 10 ? Color.green : Color.orange,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int((CGFloat(voiceMinutesRemaining) / 100.0) * 100))%")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Usage info
                VStack(spacing: 8) {
                    HStack {
                        Text("Plan Limit:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(subscriptionType == "Pro" ? "Unlimited" : "100 min/month")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if subscriptionType == "Free" && voiceMinutesRemaining <= 10 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            
                            Text("Running low on minutes")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Spacer()
                            
                            Button("Upgrade") {
                                subscriptionType = "Pro"
                                voiceMinutesRemaining = 999 // Mock unlimited
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(4)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .appCardStyle()
        }
    }

    private var draftingStyleSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "pencil.and.outline").foregroundColor(.blue).font(.headline)
                Text("Drafting Style").font(.headline).foregroundColor(.white)
                Spacer()
            }
            VStack(spacing: 12) {
                ForEach(draftingOptions, id: \.self) { option in
                    Button {
                        if option == "Custom" && !customStyleConfigured {
                            showingCustomSetup = true
                        } else {
                            draftingStyle = option
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(draftingStyle == option ? Color.blue : Color.clear)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 2))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option).foregroundColor(.white)
                                
                                if option == "Custom" {
                                    Text(customStyleConfigured ? "Configured ✓" : "Setup Required")
                                        .font(.caption)
                                        .foregroundColor(customStyleConfigured ? .green.opacity(0.8) : .orange.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                            
                            if option == "Custom" && customStyleConfigured {
                                Button("Edit") {
                                    showingCustomSetup = true
                                }
                                .font(.caption.weight(.medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.vertical, option == "Custom" ? 12 : 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .appCardStyle()
        }
    }

    private var voiceSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "waveform").foregroundColor(.blue).font(.headline)
                Text("Voice").font(.headline).foregroundColor(.white)
                Spacer()
            }
            VStack(spacing: 12) {
                ForEach(voiceOptions, id: \.self) { option in
                    Button { voiceModel = option } label: {
                        HStack {
                            Circle()
                                .fill(voiceModel == option ? Color.blue : Color.clear)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 2))
                            Text(option).foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .appCardStyle()
        }
    }

    private var subscriptionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "crown").foregroundColor(.blue).font(.headline)
                Text("Subscription").font(.headline).foregroundColor(.white)
                Spacer()
            }
            HStack {
                Text("Plan:").foregroundColor(.white.opacity(0.85))
                Text(subscriptionType)
                    .foregroundColor(subscriptionType == "Pro" ? .yellow : .white)
                    .fontWeight(.semibold)
                if subscriptionType == "Pro" {
                    Image(systemName: "crown.fill").foregroundColor(.yellow).font(.caption)
                }
                Spacer()
                if subscriptionType == "Free" {
                    Button("Upgrade") {
                        subscriptionType = "Pro"
                        voiceMinutesRemaining = 999 // Mock unlimited minutes
                    }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
            }
            .appCardStyle()
        }
    }

    private var connectionStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "link").foregroundColor(.blue).font(.headline)
                Text("Connection Status").font(.headline).foregroundColor(.white)
                Spacer()
            }
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "envelope").foregroundColor(.white.opacity(0.6)).frame(width: 20)
                    Text("Gmail").foregroundColor(.white)
                    Spacer()
                    Circle().fill(gmailConnected ? Color.green : Color.red).frame(width: 8, height: 8)
                    Text(gmailConnected ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(gmailConnected ? .green : .red.opacity(0.8))
                }
                HStack {
                    Image(systemName: "calendar").foregroundColor(.white.opacity(0.6)).frame(width: 20)
                    Text("Calendar").foregroundColor(.white)
                    Spacer()
                    Circle().fill(calendarConnected ? Color.green : Color.red).frame(width: 8, height: 8)
                    Text(calendarConnected ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(calendarConnected ? .green : .red.opacity(0.8))
                    if !calendarConnected {
                        Button("Connect") { calendarConnected = true }
                            .font(.caption.weight(.medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .appCardStyle()
        }
    }
}

#Preview { SettingsView() }
