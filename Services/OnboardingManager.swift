//  OnboardingManager.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/9/25.


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
    
    // Polling state
    @Published var isPollingForCompletion = false

    private let supabaseSvc = SupabaseService()
    private let api = APIService()
    
    // Polling configuration
    private let maxPollingAttempts = 10
    private let initialPollingDelay: TimeInterval = 1.0 // Start with 1 second
    private let maxPollingDelay: TimeInterval = 8.0   // Cap at 8 seconds

    // MARK: - Check onboarding status
    func refreshStatus() async {
        await withLoading {
            print("[OnboardingManager] Refreshing onboarding status…")
            let token = try await self.supabaseSvc.currentAccessToken()
            let status = try await self.api.getOnboardingStatus(accessToken: token)
            self.needsOnboarding = !status.onboardingCompleted
            self.step = OnboardingStep(from: status.step)
            self.gmailConnected = status.gmailConnected
            print("[OnboardingManager] Status → step=\(self.step), needsOnboarding=\(self.needsOnboarding), gmailConnected=\(self.gmailConnected)")
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
        
        do {
            let token = try await self.supabaseSvc.currentAccessToken()

            // Step 1: Retrieve data from backend
            let retrieve = try await self.api.retrieveGmailOAuthData(
                accessToken: token,
                state: state
            )
            print("[OnboardingManager] Retrieved OAuth data from backend: code=\(retrieve.code.prefix(8))…, state=\(retrieve.state)")

            // Step 2: Finish OAuth and follow backend navigation instructions
            let response = try await self.api.postGmailCallback(
                accessToken: token,
                code: retrieve.code,
                state: retrieve.state
            )
            print("[OnboardingManager] OAuth callback response: nextStep=\(response.nextStep), gmailConnected=\(response.gmailConnected)")

            // 🔥 Follow backend navigation instructions directly
            switch response.nextStep {
            case "redirect_to_main_app":
                print("[OnboardingManager] Backend says: redirect to main app")
                self.needsOnboarding = false
                self.step = .completed
                
            case "stay_on_gmail":
                print("[OnboardingManager] Backend says: stay on Gmail view")
                self.gmailConnected = response.gmailConnected
                
            case "go_to_profile_step":
                print("[OnboardingManager] Backend says: go to profile step")
                self.step = .profile
                
            default:
                print("[OnboardingManager] Backend says: default action, nextStep=\(response.nextStep)")
                self.gmailConnected = response.gmailConnected
            }

            // Clean up pending state
            UserDefaults.standard.removeObject(forKey: "gmail_oauth_state")
            print("[OnboardingManager] Cleared gmail_oauth_state")
            
        } catch {
            print("[OnboardingManager][Error] \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Production Polling Logic (Fallback - should not be needed now)
    private func pollForOnboardingCompletion() async {
        print("[OnboardingManager] Starting polling for onboarding completion...")
        
        var attempts = 0
        let quickRetries = 3      // Quick retries for race condition
        let quickDelay = 0.2      // 200ms for quick retries
        var delay = initialPollingDelay
        
        while attempts < maxPollingAttempts {
            attempts += 1
            print("[OnboardingManager] Polling attempt \(attempts)/\(maxPollingAttempts)")
            
            // Use shorter delays for first few attempts (race condition fix)
            let currentDelay = attempts <= quickRetries ? quickDelay : delay
            
            // Wait before checking
            try? await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
            
            do {
                let token = try await self.supabaseSvc.currentAccessToken()
                let status = try await self.api.getOnboardingStatus(accessToken: token)
                
                print("[OnboardingManager] Poll result → step: \(status.step), completed: \(status.onboardingCompleted)")
                
                // Check if onboarding is complete
                if status.onboardingCompleted || status.step == .completed {
                    print("[OnboardingManager] ✅ Onboarding completed via polling! Updating state...")
                    self.needsOnboarding = false
                    self.step = .completed
                    self.gmailConnected = status.gmailConnected
                    return // Success! Stop polling
                }
                
                // Update current state but continue polling
                self.step = OnboardingStep(from: status.step)
                self.gmailConnected = status.gmailConnected
                
            } catch {
                print("[OnboardingManager] Polling error: \(error.localizedDescription)")
            }
            
            // Only use exponential backoff after quick retries
            if attempts > quickRetries {
                delay = min(delay * 1.5 + Double.random(in: 0...0.5), maxPollingDelay)
            }
        }
        
        print("[OnboardingManager] ⚠️ Polling timeout reached. Manual refresh may be needed.")
        // Final attempt to refresh status
        await refreshStatus()
    }

    func completeGmailAuth(code: String, state: String) async {
        isPollingForCompletion = true
        
        await withLoading {
            print("[OnboardingManager] Completing Gmail auth manually with code=\(code.prefix(8))… and state=\(state)")
            let token = try await self.supabaseSvc.currentAccessToken()
            let response = try await self.api.postGmailCallback(
                accessToken: token,
                code: code,
                state: state
            )
            
            // Follow backend navigation instructions
            switch response.nextStep {
            case "redirect_to_main_app":
                print("[OnboardingManager] Backend says: redirect to main app")
                self.needsOnboarding = false
                self.step = .completed
                
            case "stay_on_gmail":
                print("[OnboardingManager] Backend says: stay on Gmail view")
                self.gmailConnected = response.gmailConnected
                
            case "go_to_profile_step":
                print("[OnboardingManager] Backend says: go to profile step")
                self.step = .profile
                
            default:
                print("[OnboardingManager] Backend says: default action")
                self.gmailConnected = response.gmailConnected
            }
        }
        
        isPollingForCompletion = false
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
    
    // MARK: - Manual completion (fallback)
    func forceCompleteOnboarding() async {
        print("[OnboardingManager] Manual completion requested")
        await refreshStatus()
        
        // If backend still hasn't marked as complete, allow manual override
        if !needsOnboarding {
            print("[OnboardingManager] Backend confirms completion")
        } else {
            print("[OnboardingManager] Backend not ready, but user wants to continue")
            self.step = .completed
            self.needsOnboarding = false
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
