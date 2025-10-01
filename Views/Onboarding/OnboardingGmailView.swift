//
//  OnboardingGmailView.swift
//  voice-gmail-assistant
//
//  FIXED: Removed race condition between error and success states

import SwiftUI

struct OnboardingGmailView: View {
    @EnvironmentObject var onboarding: OnboardingManager
    
    // Auto-polling state
    @State private var isAutoPolling = false
    @State private var pollAttempts = 0
    @State private var showPollingUI = false
    
    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 36) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.badge")
                            .font(.system(size: 48, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 48, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.blue)
                    }
                    .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)

                    Text("Connect Google Services")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text("Link your Gmail and Google Calendar so you can use voice commands to manage email and schedule events.")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Main content area
                VStack(spacing: 20) {
                    
                    // ✅ FIX: Success state takes priority over error state
                    if onboarding.gmailConnected {
                        // Success state (Gmail connected successfully)
                        VStack(spacing: 20) {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                                    .shadow(color: Color.green.opacity(0.3), radius: 8, y: 4)
                                
                                Text("Google Services Connected!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                                
                                Text("You can now use voice commands to manage your email and calendar.")
                                    .font(.callout)
                                    .foregroundColor(.white.opacity(0.85))
                                    .multilineTextAlignment(.center)
                            }
                            .appCardStyle()
                            .padding(.horizontal, 24)
                            
                            // Continue button
                            Button {
                                Task {
                                    onboarding.needsOnboarding = false
                                }
                            } label: {
                                if onboarding.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Label("Continue to App", systemImage: "arrow.right")
                                }
                            }
                            .appButtonStyle(disabled: onboarding.isLoading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 44)
                        }
                    }
                    // Auto-polling state (waiting for OAuth)
                    else if showPollingUI {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.blue)
                            
                            VStack(spacing: 8) {
                                Text("Waiting for Google connection...")
                                    .font(.callout)
                                    .foregroundColor(.white.opacity(0.85))
                                
                                Text("This usually takes a few seconds")
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            // Manual refresh option after prolonged wait
                            if pollAttempts > 6 {
                                Button {
                                    Task {
                                        stopAutoPolling()
                                        await onboarding.completeGmailAuthIfPending()
                                        await onboarding.refreshStatus()
                                    }
                                } label: {
                                    Label("Check Again", systemImage: "arrow.clockwise")
                                        .font(.footnote)
                                        .foregroundColor(.white.opacity(0.85))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .appCardStyle()
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 44)
                    }
                    // Processing state (OAuth completing)
                    else if onboarding.isProcessingOAuth {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.blue)
                            
                            Text("Completing Google connection...")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .appCardStyle()
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 44)
                    }
                    // Error state (connection failed) - only show if NOT connected
                    else if let error = onboarding.errorMessage, !onboarding.gmailConnected {
                        VStack(spacing: 20) {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.orange)
                                    .shadow(color: Color.orange.opacity(0.3), radius: 8, y: 4)
                                
                                Text("Connection Failed")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                Text(error)
                                    .font(.callout)
                                    .foregroundColor(.white.opacity(0.85))
                                    .multilineTextAlignment(.center)
                            }
                            .appCardStyle()
                            .padding(.horizontal, 24)
                            
                            // Try again button
                            Button {
                                Task { await onboarding.retryGmailConnection() }
                            } label: {
                                if onboarding.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Label("Try Again", systemImage: "arrow.clockwise")
                                }
                            }
                            .appButtonStyle(disabled: onboarding.isLoading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 44)
                        }
                    }
                    // Initial state (ready to connect)
                    else {
                        VStack(spacing: 20) {
                            // Main connect button
                            Button {
                                Task {
                                    await onboarding.startGmailAuth()
                                    startAutoPolling()
                                }
                            } label: {
                                if onboarding.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Label("Connect Google Services", systemImage: "arrow.right")
                                }
                            }
                            .appButtonStyle(disabled: onboarding.isLoading)
                            .padding(.horizontal, 24)
                            
                            // Info text
                            Text("You'll be redirected to Google to sign in securely")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.bottom, 44)
                        }
                    }
                }
            }
        }
        .onAppear {
            // Check for pending OAuth when view appears
            if UserDefaults.standard.string(forKey: "gmail_oauth_state") != nil &&
               !onboarding.isProcessingOAuth &&
               !onboarding.gmailConnected {
                startAutoPolling()
            }
        }
        .onDisappear {
            stopAutoPolling()
        }
        // ✅ FIX: Clear error message when connection succeeds
        .onChange(of: onboarding.gmailConnected) { isConnected in
            if isConnected {
                // Clear any error message when successfully connected
                onboarding.errorMessage = nil
                stopAutoPolling()
            }
        }
    }
    
    // MARK: - Auto-Polling Logic
    
    private func startAutoPolling() {
        guard !isAutoPolling else { return }
        
        print("🔍 [GmailView] Starting auto-polling for OAuth completion")
        isAutoPolling = true
        pollAttempts = 0
        showPollingUI = true
        
        Task {
            await pollForOAuthCompletion()
        }
    }
    
    private func stopAutoPolling() {
        print("🔍 [GmailView] Stopping auto-polling")
        isAutoPolling = false
        showPollingUI = false
        pollAttempts = 0
    }
    
    private func pollForOAuthCompletion() async {
        guard isAutoPolling else { return }
        
        // ✅ FIX: Check if already processing to prevent duplicate calls
        guard !onboarding.isProcessingOAuth else {
            print("🔍 [GmailView] Already processing OAuth, skipping this poll")
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
            await pollForOAuthCompletion() // Try again
            return
        }
        
        // Check if we still have pending OAuth state
        guard UserDefaults.standard.string(forKey: "gmail_oauth_state") != nil else {
            print("🔍 [GmailView] No OAuth state found, stopping polling")
            stopAutoPolling()
            return
        }
        
        // ✅ FIX: Check if already connected before trying again
        if onboarding.gmailConnected {
            print("🔍 [GmailView] Already connected, stopping polling")
            stopAutoPolling()
            return
        }
        
        pollAttempts += 1
        print("🔍 [GmailView] Polling attempt \(pollAttempts)")
        
        // Try to complete OAuth
        await onboarding.completeGmailAuthIfPending()
        
        // Check if successful
        if onboarding.gmailConnected {
            print("🔍 [GmailView] OAuth completed successfully, stopping polling")
            stopAutoPolling()
            return
        }
        
        // Continue polling if we haven't exceeded max attempts
        if pollAttempts < 20 && isAutoPolling {
            // Wait before next attempt
            try? await Task.sleep(nanoseconds: 6_000_000_000) // 6 seconds
            
            // Continue polling
            await pollForOAuthCompletion()
        } else {
            print("🔍 [GmailView] Max polling attempts reached or stopped")
            stopAutoPolling()
        }
    }
}

#Preview("Normal State") {
    OnboardingGmailView()
        .environmentObject({
            let mgr = OnboardingManager()
            mgr.gmailConnected = false
            mgr.errorMessage = nil
            mgr.isLoading = false
            mgr.isProcessingOAuth = false
            return mgr
        }())
}

#Preview("Success State") {
    OnboardingGmailView()
        .environmentObject({
            let mgr = OnboardingManager()
            mgr.gmailConnected = true
            mgr.errorMessage = nil
            mgr.isLoading = false
            mgr.isProcessingOAuth = false
            return mgr
        }())
}

#Preview("Error State") {
    OnboardingGmailView()
        .environmentObject({
            let mgr = OnboardingManager()
            mgr.gmailConnected = false
            mgr.errorMessage = "Failed to connect Gmail. Please check your network connection and try again."
            mgr.isLoading = false
            mgr.isProcessingOAuth = false
            return mgr
        }())
}
