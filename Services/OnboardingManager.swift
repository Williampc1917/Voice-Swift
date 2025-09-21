//  OnboardingManager.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/9/25.

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
    
    // New: OAuth completion state
    @Published var isProcessingOAuth = false

    private let supabaseSvc = SupabaseService()
    private let api = APIService()

    // MARK: - Check onboarding status
    func refreshStatus() async {
        await withLoading {
            print("🔍 [OnboardingManager] Refreshing onboarding status…")
            let token = try await self.supabaseSvc.currentAccessToken()
            let status = try await self.api.getOnboardingStatus(accessToken: token)
            self.needsOnboarding = !status.onboardingCompleted
            self.step = OnboardingStep(from: status.step)
            self.gmailConnected = status.gmailConnected
            print("🔍 [OnboardingManager] Status → step=\(self.step), needsOnboarding=\(self.needsOnboarding), gmailConnected=\(self.gmailConnected)")
        }
    }

    // MARK: - Submit profile name
    func submitDisplayName(_ name: String) async {
        await withLoading {
            print("🔍 [OnboardingManager] Submitting display name=\(name)")
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
            print("🔍 [OnboardingManager] Starting Gmail OAuth…")
            
            // Clear any previous error
            self.errorMessage = nil
            
            let token = try await self.supabaseSvc.currentAccessToken()
            let response = try await self.api.getGmailAuthURL(accessToken: token)

            // Save state for later
            self.gmailState = response.state
            UserDefaults.standard.set(response.state, forKey: "gmail_oauth_state")
            print("🔍 [OnboardingManager] Saved gmail_oauth_state=\(response.state)")

            // Open Google login in Safari
            if let url = URL(string: response.authUrl) {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    // MARK: - Enhanced OAuth Completion (polling-friendly)
    func completeGmailAuthIfPending() async {
        guard let state = UserDefaults.standard.string(forKey: "gmail_oauth_state") else {
            print("🔍 [OnboardingManager] No pending OAuth state")
            return
        }

        // Prevent multiple simultaneous completion attempts
        guard !isProcessingOAuth else {
            print("🔍 [OnboardingManager] OAuth completion already in progress")
            return
        }

        print("🔍 [OnboardingManager] Processing OAuth completion...")
        self.isProcessingOAuth = true
        
        do {
            let token = try await self.supabaseSvc.currentAccessToken()
            
            // Step 1: Try to retrieve OAuth data (this might fail if backend hasn't processed it yet)
            let retrieve: GmailRetrieveResponse
            do {
                retrieve = try await self.api.retrieveGmailOAuthData(accessToken: token, state: state)
                print("🔍 [OnboardingManager] Retrieved OAuth data successfully")
            } catch {
                // If retrieval fails, it might be too early - this is normal for polling
                if error.localizedDescription.contains("404") {
                    print("🔍 [OnboardingManager] OAuth data not ready yet (404) - this is normal during polling")
                    self.isProcessingOAuth = false
                    return // Exit gracefully for polling to try again
                } else {
                    throw error // Re-throw other errors
                }
            }
            
            // Step 2: Complete OAuth
            let response = try await self.api.postGmailCallback(
                accessToken: token,
                code: retrieve.code,
                state: retrieve.state
            )
            print("🔍 [OnboardingManager] OAuth completed successfully")
            
            // Clean up immediately on success
            UserDefaults.standard.removeObject(forKey: "gmail_oauth_state")
            
            // Clear any previous errors
            self.errorMessage = nil
            
            // Update state in a coordinated way to prevent race conditions
            await self.refreshStatusAndCompleteOnboardingIfReady()
            
        } catch {
            print("🔍 [OnboardingManager] OAuth error: \(error)")
            
            // Only clean up state and show error if it's not a "too early" error
            if !error.localizedDescription.contains("404") {
                // Clean up state on error
                UserDefaults.standard.removeObject(forKey: "gmail_oauth_state")
                
                // Set user-friendly error messages
                if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                    self.errorMessage = "Network error. Please check your connection and try again."
                } else if error.localizedDescription.contains("prepared statement") || error.localizedDescription.contains("database") {
                    self.errorMessage = "Server is temporarily busy. Please try again in a moment."
                } else {
                    self.errorMessage = "Failed to connect Gmail. Please try again."
                }
                
                // Refresh Gmail status to show current state
                await self.refreshGmailStatus()
            }
            // For 404 errors during polling, we just exit gracefully without setting errors
        }
        
        self.isProcessingOAuth = false
    }

    // MARK: - Coordinated status refresh and onboarding completion
    private func refreshStatusAndCompleteOnboardingIfReady() async {
        await withLoading {
            let token = try await self.supabaseSvc.currentAccessToken()
            let status = try await self.api.getOnboardingStatus(accessToken: token)
            
            // Update all state atomically
            self.gmailConnected = status.gmailConnected
            self.step = OnboardingStep(from: status.step)
            self.needsOnboarding = !status.onboardingCompleted
            
            print("🔍 [OnboardingManager] Coordinated update → gmailConnected=\(self.gmailConnected), step=\(self.step), needsOnboarding=\(self.needsOnboarding)")
        }
    }

    // MARK: - Manual Continue (for successful OAuth)
    func continueAfterGmailSuccess() async {
        await withLoading {
            print("🔍 [OnboardingManager] User clicked continue after Gmail success")
            
            // Refresh status first
            await self.refreshStatus()
            
            // If onboarding is complete, advance to completed step
            if !self.needsOnboarding {
                self.step = .completed
                print("🔍 [OnboardingManager] Onboarding completed, advancing to main app")
            } else {
                print("🔍 [OnboardingManager] Onboarding still needed, staying in flow")
            }
        }
    }

    // MARK: - Retry mechanism
    func retryGmailConnection() async {
        print("🔍 [OnboardingManager] Retrying Gmail connection")
        
        // Clear error state
        self.errorMessage = nil
        
        // Start fresh OAuth flow
        await self.startGmailAuth()
    }

    // MARK: - Gmail Status Management
    func refreshGmailStatus() async {
        await withLoading {
            print("🔍 [OnboardingManager] Refreshing Gmail connection status…")
            let token = try await self.supabaseSvc.currentAccessToken()
            let response = try await self.api.getGmailAuthStatus(accessToken: token)
            self.gmailConnected = response.connected
            print("🔍 [OnboardingManager] Gmail status connected=\(self.gmailConnected)")
        }
    }

    func disconnectGmail() async {
        await withLoading {
            print("🔍 [OnboardingManager] Disconnecting Gmail…")
            let token = try await self.supabaseSvc.currentAccessToken()
            _ = try await self.api.disconnectGmail(accessToken: token)
            self.gmailConnected = false
            self.errorMessage = nil
            print("🔍 [OnboardingManager] Gmail disconnected.")
        }
    }

    // MARK: - Utility wrapper
    private func withLoading(_ work: @escaping () async throws -> Void) async {
        self.isLoading = true
        do {
            try await work()
        } catch {
            print("🔍 [OnboardingManager][Error] \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
        self.isLoading = false
    }
}
