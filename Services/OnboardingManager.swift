//  OnboardingManager.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/9/25.
//

import Foundation
import SwiftUI

// MARK: - Clean Domain Models (UI-facing)
enum OnboardingStep {
    case start
    case profile
    case gmail
    case completed
}

extension OnboardingStep {
    init(from wire: WireOnboardingStep) {
        switch wire {
        case .start: self = .start
        case .profile: self = .profile
        case .gmail: self = .gmail
        case .completed: self = .completed
        }
    }
}

@MainActor
final class OnboardingManager: ObservableObject {
    // MARK: - Published state for UI
    @Published var needsOnboarding = false
    @Published var step: OnboardingStep = .start
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Gmail-related
    @Published var gmailConnected: Bool = false
    @Published var gmailState: String?

    private let supabaseSvc = SupabaseService()
    private let api = APIService()

    // MARK: - Check onboarding status
    func refreshStatus() async {
        await withLoading {
            print("[OnboardingManager] Refreshing onboarding status…")
            let token = try await self.supabaseSvc.currentAccessToken()
            let status = try await self.api.getOnboardingStatus(accessToken: token)
            self.needsOnboarding = !status.onboardingCompleted
            self.step = OnboardingStep(from: status.step)
            print("[OnboardingManager] Status → step=\(self.step), needsOnboarding=\(self.needsOnboarding)")
        }
    }

    // MARK: - Submit profile name
    func submitDisplayName(_ name: String) async {
        await withLoading {
            print("[OnboardingManager] Submitting display name=\(name)")
            let token = try await self.supabaseSvc.currentAccessToken()
            _ = try await self.api.updateProfileName(
                accessToken: token,
                displayName: name,
                timezone: TimeZone.current.identifier
            )
            await self.refreshStatus()
        }
    }

    // MARK: - Gmail Flow
    func startGmailAuth() async {
        await withLoading {
            print("[OnboardingManager] Starting Gmail OAuth…")
            let token = try await self.supabaseSvc.currentAccessToken()
            let response = try await self.api.getGmailAuthURL(accessToken: token)

            // Save state for later
            self.gmailState = response.state
            UserDefaults.standard.set(response.state, forKey: "gmail_oauth_state")
            print("[OnboardingManager] Saved gmail_oauth_state=\(response.state)")

            // Open Google login in Safari
            if let url = URL(string: response.authUrl) {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    func completeGmailAuthIfPending() async {
        guard let state = UserDefaults.standard.string(forKey: "gmail_oauth_state") else {
            print("[OnboardingManager] No pending Gmail OAuth state found.")
            return
        }

        print("[OnboardingManager] Found pending Gmail OAuth state=\(state). Attempting to complete…")

        await withLoading {
            let token = try await self.supabaseSvc.currentAccessToken()

            // Step 1: Retrieve data from backend
            let retrieve = try await self.api.retrieveGmailOAuthData(
                accessToken: token,
                state: state
            )
            print("[OnboardingManager] Retrieved OAuth data from backend: code=\(retrieve.code.prefix(8))…, state=\(retrieve.state)")

            // Step 2: Finish OAuth
            let response = try await self.api.postGmailCallback(
                accessToken: token,
                code: retrieve.code,
                state: retrieve.state
            )
            print("[OnboardingManager] Completed OAuth callback. gmailConnected=\(response.gmailConnected)")

            // Step 3: Mark connected
            self.gmailConnected = response.gmailConnected
            if response.gmailConnected {
                print("[OnboardingManager] Gmail connected! Refreshing status…")
                await self.refreshStatus()
            }

            // Clean up pending state
            UserDefaults.standard.removeObject(forKey: "gmail_oauth_state")
            print("[OnboardingManager] Cleared gmail_oauth_state")
        }
    }

    func completeGmailAuth(code: String, state: String) async {
        await withLoading {
            print("[OnboardingManager] Completing Gmail auth manually with code=\(code.prefix(8))… and state=\(state)")
            let token = try await self.supabaseSvc.currentAccessToken()
            let response = try await self.api.postGmailCallback(
                accessToken: token,
                code: code,
                state: state
            )
            self.gmailConnected = response.gmailConnected
            if response.gmailConnected {
                await self.refreshStatus()
            }
        }
    }

    func refreshGmailStatus() async {
        await withLoading {
            print("[OnboardingManager] Refreshing Gmail connection status…")
            let token = try await self.supabaseSvc.currentAccessToken()
            let response = try await self.api.getGmailStatus(accessToken: token)
            self.gmailConnected = response.connected
            print("[OnboardingManager] Gmail status connected=\(self.gmailConnected)")
        }
    }

    func disconnectGmail() async {
        await withLoading {
            print("[OnboardingManager] Disconnecting Gmail…")
            let token = try await self.supabaseSvc.currentAccessToken()
            _ = try await self.api.disconnectGmail(accessToken: token)
            self.gmailConnected = false
            print("[OnboardingManager] Gmail disconnected.")
        }
    }

    // MARK: - Utility wrapper
    private func withLoading(_ work: @escaping () async throws -> Void) async {
        self.isLoading = true
        self.errorMessage = nil
        do {
            try await work()
        } catch {
            print("[OnboardingManager][Error] \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
        self.isLoading = false
    }
}
