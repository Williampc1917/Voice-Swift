//
//  voice_gmail_assistantApp.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//

import SwiftUI

@main
struct VoiceGmailAssistantApp: App {
    @StateObject private var auth = AuthManager()
    @StateObject private var onboarding = OnboardingManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(onboarding)
                // 👇 This detects when the app becomes active (user switches back from Safari)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    Task {
                        await onboarding.completeGmailAuthIfPending()
                    }
                }
        }
    }
}
