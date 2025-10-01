//  OnboardingManager.swift
//  voice-gmail-assistant
//
//  FIXED: Proper handling of email style step completion
//

import Foundation
import SwiftUI

// MARK: - Clean Domain Models (UI-facing)
enum OnboardingStep {
    case start
    case profile
    case gmail
    case emailStyle
    case completed
}

extension OnboardingStep {
    init(from wire: WireOnboardingStep) {
        switch wire {
        case .start: self = .start
        case .profile: self = .profile
        case .gmail: self = .gmail
        case .emailStyle: self = .emailStyle
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
    
    // OAuth completion state
    @Published var isProcessingOAuth = false
    
    // Email Style-related properties
    @Published var emailStyleSelected: Bool = false
    @Published var availableEmailStyles: [EmailStyleOption] = []
    @Published var currentEmailStyle: String?
    @Published var canAdvanceFromEmailStyle: Bool = false

    private let supabaseSvc = SupabaseService()
    private let api = APIService()

    func refreshStatus() async {
        await withLoading {
            print("🔍 [OnboardingManager] Refreshing onboarding status…")
            let token = try await self.supabaseSvc.currentAccessToken()
            let status = try await self.api.getOnboardingStatus(accessToken: token)
            
            self.needsOnboarding = !status.onboardingCompleted
            self.step = OnboardingStep(from: status.step)
            self.gmailConnected = status.gmailConnected
            
            // ✅ FIX: Only load email style options if actually on that step
            if self.step == .emailStyle && !status.onboardingCompleted {
                do {
                    try await self.loadEmailStyleOptionsInternal(token: token)
                } catch {
                    print("⚠️ [OnboardingManager] Failed to load email style options: \(error)")
                    // Don't fail the whole refresh, just log the error
                }
            }
            
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
            
            // Step 1: Try to retrieve OAuth data
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
            
            // ✅ CRITICAL FIX: Handle next step action using type-safe enum
            switch response.nextStepAction {
            case .goToEmailStyle:
                print("🔍 [OnboardingManager] Advancing to email style selection")
                self.gmailConnected = true
                self.step = .emailStyle
                // ✅ DO NOT set needsOnboarding = false here!
                // Let the backend control that via refreshStatus()
                
                // Load email style options immediately
                await self.loadEmailStyleOptions()
                
            case .completed:
                print("🔍 [OnboardingManager] Onboarding completed by backend")
                self.gmailConnected = true
                // ✅ Refresh status to get the actual completed state from backend
                await self.refreshStatus()
                
            case .stayOnGmail:
                print("🔍 [OnboardingManager] Staying on Gmail step (error)")
                self.errorMessage = response.message
                
            case .redirectToMainApp:
                print("🔍 [OnboardingManager] Redirecting to main app")
                await self.refreshStatus() // Get fresh status from backend
                
            case .goToProfileStep:
                print("🔍 [OnboardingManager] Going back to profile step")
                self.step = .profile
                
            case .unknown(let value):
                print("⚠️ [OnboardingManager] Unknown next step: \(value)")
                // Fallback: refresh status to get current state
                await self.refreshStatus()
            }
            
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
        }
        
        self.isProcessingOAuth = false
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

    // MARK: - Email Style Methods
    
    /// Load available email style options
    func loadEmailStyleOptions() async {
        await withLoading {
            print("🔍 [OnboardingManager] Loading email style options…")
            let token = try await self.supabaseSvc.currentAccessToken()
            try await self.loadEmailStyleOptionsInternal(token: token)
        }
    }
    
    /// Internal method to load options without extra loading wrapper
    private func loadEmailStyleOptionsInternal(token: String) async throws {
        let response = try await self.api.getEmailStyleOptions(accessToken: token)
        
        self.availableEmailStyles = response.availableOptions
        self.currentEmailStyle = response.styleSelected
        self.canAdvanceFromEmailStyle = response.canAdvance
        self.emailStyleSelected = response.styleSelected != nil
        
        print("🔍 [OnboardingManager] Email style options loaded:")
        print("🔍 [OnboardingManager] - Available options: \(self.availableEmailStyles.count)")
        print("🔍 [OnboardingManager] - Current style: \(self.currentEmailStyle ?? "none")")
        print("🔍 [OnboardingManager] - Can advance: \(self.canAdvanceFromEmailStyle)")
    }
    
    /// Select a predefined email style (Casual or Professional)
    func selectPredefinedStyle(_ style: APIService.PredefinedEmailStyle) async {
        await withLoading {
            print("🔍 [OnboardingManager] Selecting predefined style: \(style.rawValue)")
            let token = try await self.supabaseSvc.currentAccessToken()
            
            let response = try await self.api.selectEmailStyle(
                accessToken: token,
                style: style
            )
            
            print("🔍 [OnboardingManager] Style selected successfully: \(response.styleType)")
            
            // Update local state
            self.currentEmailStyle = response.styleType
            self.emailStyleSelected = true
            self.canAdvanceFromEmailStyle = true
            
            // ✅ CRITICAL FIX: Don't set needsOnboarding here!
            // Let refreshStatus() handle it after backend confirms completion
            if response.nextStep == "completed" {
                print("🔍 [OnboardingManager] Backend says onboarding is complete, refreshing status")
                // Refresh status to get the actual completion state from backend
                await self.refreshStatus()
            }
        }
    }
    
    /// Create a custom email style from examples
    func createCustomStyle(emailExamples: [String]) async -> CustomEmailStyleResponse? {
        var result: CustomEmailStyleResponse?
        
        await withLoading {
            print("🔍 [OnboardingManager] Creating custom email style with \(emailExamples.count) examples")
            let token = try await self.supabaseSvc.currentAccessToken()
            
            let response = try await self.api.createCustomEmailStyle(
                accessToken: token,
                emailExamples: emailExamples
            )
            
            result = response
            
            if response.success {
                print("🔍 [OnboardingManager] Custom style created successfully")
                print("🔍 [OnboardingManager] - Grade: \(response.extractionGrade ?? "unknown")")
                
                // Update local state
                self.currentEmailStyle = "custom"
                self.emailStyleSelected = true
                self.canAdvanceFromEmailStyle = true
                
                // ✅ CRITICAL FIX: Don't set needsOnboarding here!
                // Let refreshStatus() handle it after backend confirms completion
                if response.nextStep == "completed" {
                    print("🔍 [OnboardingManager] Backend says onboarding is complete, refreshing status")
                    // Refresh status to get the actual completion state from backend
                    await self.refreshStatus()
                }
            } else {
                print("🔍 [OnboardingManager] Custom style creation failed: \(response.errorMessage ?? "unknown error")")
                
                // Set user-friendly error
                if response.isRateLimitError {
                    self.errorMessage = response.friendlyError
                } else {
                    self.errorMessage = "Failed to create custom style. Please try again with different email examples."
                }
            }
        }
        
        return result
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
