//
//  MainPageView.swift
//  voice-gmail-assistant
//
//  Mission Control — Claro AI color scheme (coral + navy)
//

import SwiftUI
import Foundation

// MARK: - Font helper (Silkscreen with safe fallback)
#if canImport(UIKit)
import UIKit
#endif

extension Font {
    /// Attempts Silkscreen by PostScript name, with graceful fallback.
    static func silkscreen(_ size: CGFloat, relativeTo style: Font.TextStyle = .title3) -> Font {
        #if canImport(UIKit)
        if UIFont(name: "Silkscreen-Regular", size: size) != nil {
            return .custom("Silkscreen-Regular", size: size, relativeTo: style)
        }
        if UIFont(name: "Silkscreen", size: size) != nil {
            return .custom("Silkscreen", size: size, relativeTo: style)
        }
        #endif
        return .system(size: size, weight: .semibold, design: .monospaced)
    }
}

// MARK: - Brand colors (Display-P3 for vibrancy)
private enum Brand {
    static let coral = Color(.displayP3, red: 224/255, green: 122/255, blue: 95/255)       // #E07A5F
    static let navy  = Color(.displayP3, red:  61/255, green:  64/255, blue: 91/255)       // #3D405B
    static let mint  = Color(.displayP3, red: 110/255, green: 198/255, blue: 166/255)

    // Alerts
    static let alertRed    = Color(.displayP3, red: 245/255, green:  34/255, blue:  45/255) // #F5222D
    static let alertYellow = Color(.displayP3, red: 250/255, green: 173/255, blue:  20/255) // #FAAD14
    static let alertBlue   = Color(.displayP3, red:  24/255, green: 144/255, blue: 255/255) // #1890FF

    // Severity (muted, for Smart Alerts)
    static let sevDanger  = Color(.displayP3, red: 161/255, green:  75/255, blue:  75/255) // #A14B4B
    static let sevWarning = Color(.displayP3, red: 142/255, green: 111/255, blue:  62/255) // #8E6F3E
    static let sevInfo    = Color(.displayP3, red:  76/255, green: 118/255, blue: 184/255) // #4C76B8

    // Background (dark slate, wide-gamut)
    static let bgTop     = Color(.displayP3, red: 11/255, green: 13/255, blue: 17/255)   // #0B0D11
    static let bgMid     = Color(.displayP3, red: 16/255, green: 20/255, blue: 26/255)   // #10141A
    static let bgBottom  = Color(.displayP3, red: 23/255, green: 27/255, blue: 34/255)   // #171B22
    static let coralGlow = Color(.displayP3, red: 234/255, green: 132/255, blue: 103/255) // #EA8467
}

struct MainPageView: View {
    @State private var showingSettings = false
    @State private var showingVoiceChat = false
    @State private var safeTop: CGFloat = 0

    // Minimal app state
    @State private var voiceMinutesRemaining = 23
    @State private var gmailConnected = true
    @State private var calendarConnected = true
    @State private var pulse = false

    var body: some View {
        NavigationStack {
            ZStack {
                MainPageBackgroundView().ignoresSafeArea()

                GeometryReader { proxy in
                    Color.clear.preference(key: MainPageSafeTopKey.self, value: proxy.safeAreaInsets.top)
                }
                .frame(height: 0)
                .onPreferenceChange(MainPageSafeTopKey.self) { safeTop = $0 }

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.horizontal, 24)
                            .padding(.top, safeTop + 4)

                        heroVoiceSection
                            .padding(.top, 8)

                        quickActionsSection
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                        smartAlertsSection
                            .padding(.horizontal, 24)
                            .padding(.top, 12)

                        Color.clear.frame(height: 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .fullScreenCover(isPresented: $showingVoiceChat) { VoiceChatView2() }
            .onAppear { startAnimations() }
        }
    }

    // MARK: Header
    private var headerSection: some View {
        HStack {
            HStack(spacing: 4) {
                Text("CLARO")
                    .font(.silkscreen(20))
                    .foregroundColor(Brand.coral)
                    .tracking(1.0)
                Text("AI")
                    .font(.silkscreen(20))
                    .foregroundColor(.white)
                    .tracking(1.0)
            }
            Spacer()
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(UITheme.surfaceElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(UITheme.stroke, lineWidth: 1)
                            )
                    )
            }
        }
    }

    // MARK: Hero Voice Button (no shadows; circular halo to avoid square glow)
    private var heroVoiceSection: some View {
        VStack(spacing: 14) {
            Button {
                if voiceMinutesRemaining > 0 && gmailConnected {
                    showingVoiceChat = true
                }
            } label: {
                ZStack {
                    // Circular halo rendered as a blurred circle behind the button
                    Circle()
                        .fill(Brand.coral.opacity(0.28))
                        .frame(width: 190, height: 190)
                        .blur(radius: 30) // stays circular (no rectangular shadow artifacts)

                    // Solid coral button
                    Circle()
                        .fill(Brand.coral)
                        .frame(width: 146, height: 146)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .scaleEffect(pulse ? 1.06 : 1.0)

                    Image(systemName: "waveform")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(pulse ? 1.06 : 1.0)
                }
                // No .drawingGroup, no blend modes, no outer shadows (prevents wash-out & square glow)
            }
            .buttonStyle(.plain)
            .disabled(voiceMinutesRemaining <= 0 || !gmailConnected)
            .opacity(voiceMinutesRemaining <= 0 || !gmailConnected ? 0.5 : 1.0)

            Text("Start Session")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .shadow(color: .white.opacity(pulse ? 0.24 : 0.10), radius: 10, y: 1)
                .scaleEffect(pulse ? 1.04 : 1.0)
                .padding(.top, -20)

            if !gmailConnected {
                Text("Connect Gmail to get started")
                    .font(.subheadline)
                    .foregroundColor(Brand.coral)
                    .padding(.top, 4)
            } else if voiceMinutesRemaining <= 0 {
                Text("No voice minutes remaining")
                    .font(.subheadline)
                    .foregroundColor(Brand.coral)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: Quick Actions
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quick actions")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            HStack(spacing: 12) {
                QuickStartButton(
                    icon: "exclamationmark.circle.fill",
                    title: "What's urgent?",
                    color: Brand.coral
                ) { startVoiceIfAllowed() }

                QuickStartButton(
                    icon: "calendar.circle.fill",
                    title: "Today’s briefing",
                    color: Brand.mint
                ) { startVoiceIfAllowed() }
            }
        }
    }

    // MARK: Smart Alerts
    private var smartAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Alerts")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                SmartAlertCard(
                    color: Brand.sevWarning,
                    name: "Alex Wong",
                    message: "Promised follow-up \"next week\"",
                    action: "Send update"
                ) { startVoiceIfAllowed() }

                SmartAlertCard(
                    color: Brand.sevDanger,
                    name: "Sarah Lopez",
                    message: "Waiting on your reply for 2 days",
                    action: "Draft response"
                ) { startVoiceIfAllowed() }

                SmartAlertCard(
                    color: Brand.sevInfo,
                    name: "Jennifer Miller",
                    message: "Budget review in 3 hours",
                    action: "Pricing & timeline recap"
                ) { startVoiceIfAllowed() }
            }
        }
    }

    // MARK: Animations
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            pulse.toggle()
        }
    }

    // MARK: Helpers
    private func startVoiceIfAllowed() {
        if voiceMinutesRemaining > 0 && gmailConnected {
            showingVoiceChat = true
        }
    }
}

// MARK: - Supporting Views

// Shared nav pill style (matches VoiceChatView2 pills)
private struct NavPillStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(UITheme.surfaceElevated)
                    .overlay(Capsule().stroke(UITheme.stroke, lineWidth: 1))
            )
    }
}
private extension View {
    func navPill() -> some View { modifier(NavPillStyle()) }
}

private struct MainPageSafeTopKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// Quick action button (icon over title)
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
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.displayP3, red: 16/255, green: 20/255, blue: 26/255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }
}

// Smart Alert Card (no vertical bars; crisp)
struct SmartAlertCard: View {
    let color: Color
    let name: String
    let message: String
    let action: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                        Text(name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(action)
                        .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.08))
                            )
                }
                .padding(.vertical, 2)

                Spacer(minLength: 12)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.displayP3, red: 16/255, green: 20/255, blue: 26/255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }
}

/// MainPageBackgroundView — reduced global darkening to avoid washing colors
private struct MainPageBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Brand.bgTop, Brand.bgMid, Brand.bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Keep brand mood lights extremely subtle so the hero stays bright
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Brand.coralGlow.opacity(0.03), location: 0.0),
                    .init(color: .clear, location: 1.0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 520
            )

            // Edge vignette (no multiply to avoid global desaturation)
            LinearGradient(
                colors: [.black.opacity(0.18), .clear, .black.opacity(0.20)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
    }
}

#Preview {
    MainPageView()
}
