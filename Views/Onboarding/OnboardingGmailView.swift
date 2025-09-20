//
//  OnboardingGmailView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.

import SwiftUI

struct OnboardingGmailView: View {
    @EnvironmentObject var onboarding: OnboardingManager
    
    // New: Auto-polling state
    @State private var isAutoPolling = false
    @State private var pollAttempts = 0
    @State private var showPollingUI = false
    
    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 24) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    // Updated icon to represent both email and calendar
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.badge")
                            .font(.system(size: 48, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppTheme.primary)
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 48, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppTheme.primary)
                    }

                    Text("Connect Google Services")
                        .font(.title.bold())

                    Text("Link your Gmail and Google Calendar so you can use voice commands to manage email and schedule events.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Main content area
                VStack(spacing: 20) {
                    
                    // Auto-polling state (waiting for OAuth to complete)
                    if showPollingUI {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            VStack(spacing: 8) {
                                Text("Waiting for Google connection...")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                
                                Text("This usually takes a few seconds")
                                    .font(.footnote)
                                    .foregroundStyle(.tertiary)
                            }
                            
                            // Option to manually refresh if auto-polling is taking too long
                            if pollAttempts > 6 { // After ~30 seconds
                                Button {
                                    Task {
                                        stopAutoPolling()
                                        await onboarding.completeGmailAuthIfPending()
                                        await onboarding.refreshStatus()
                                    }
                                } label: {
                                    Label("Check Again", systemImage: "arrow.clockwise")
                                        .font(.footnote)
                                }
                                .buttonStyle(.bordered)
                                .tint(.secondary)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    
                    // Processing state (when OAuth is completing in background)
                    else if onboarding.isProcessingOAuth {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Completing Google connection...")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 40)
                    }
                    
                    // Success state (Gmail connected successfully)
                    else if onboarding.gmailConnected && onboarding.errorMessage == nil {
                        VStack(spacing: 20) {
                            // Success card
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.green)
                                
                                Text("Google Services Connected!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                                
                                Text("You can now use voice commands to manage your email and calendar.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .appCardStyle()
                            .padding(.horizontal, 20)
                            
                            // Continue button - goes directly to ProfileView
                            Button {
                                Task {
                                    // Direct transition to ProfileView
                                    onboarding.needsOnboarding = false
                                }
                            } label: {
                                if onboarding.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                } else {
                                    Label("Continue to App", systemImage: "arrow.right")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(onboarding.isLoading)
                            .padding(.horizontal, 20)
                            
                            // Optional: Disconnect option
                            Button("Disconnect Google Services") {
                                Task { await onboarding.disconnectGmail() }
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 40)
                    }
                    
                    // Error state (connection failed)
                    else if let error = onboarding.errorMessage {
                        VStack(spacing: 20) {
                            // Error card
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.orange)
                                
                                Text("Connection Failed")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                Text(error)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .appCardStyle()
                            .padding(.horizontal, 20)
                            
                            // Try again button
                            Button {
                                Task { await onboarding.retryGmailConnection() }
                            } label: {
                                if onboarding.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                } else {
                                    Label("Try Again", systemImage: "arrow.clockwise")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .disabled(onboarding.isLoading)
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 40)
                    }
                    
                    // Initial state (ready to connect)
                    else {
                        VStack(spacing: 16) {
                            // Main connect button
                            Button {
                                Task {
                                    await onboarding.startGmailAuth()
                                    // Start auto-polling after initiating OAuth
                                    startAutoPolling()
                                }
                            } label: {
                                if onboarding.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                } else {
                                    Label("Connect Google Services", systemImage: "arrow.right")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.primary)
                            .disabled(onboarding.isLoading)
                            .padding(.horizontal, 20)
                            
                            // Info text with what will be connected
                            VStack(spacing: 4) {
                                Text("You'll be redirected to Google to sign in securely")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            // Check if there's pending OAuth when view appears
            if UserDefaults.standard.string(forKey: "gmail_oauth_state") != nil &&
               !onboarding.isProcessingOAuth &&
               !onboarding.gmailConnected {
                
                // Start auto-polling immediately
                startAutoPolling()
            }
        }
        .onDisappear {
            // Clean up polling when leaving view
            stopAutoPolling()
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
        
        // Check if we still have pending OAuth state
        guard UserDefaults.standard.string(forKey: "gmail_oauth_state") != nil else {
            print("🔍 [GmailView] No OAuth state found, stopping polling")
            stopAutoPolling()
            return
        }
        
        pollAttempts += 1
        print("🔍 [GmailView] Polling attempt \(pollAttempts)")
        
        // Try to complete OAuth
        await onboarding.completeGmailAuthIfPending()
        
        // Check if successful
        if onboarding.gmailConnected || onboarding.errorMessage != nil {
            print("🔍 [GmailView] OAuth completed or error occurred, stopping polling")
            stopAutoPolling()
            return
        }
        
        // Continue polling if we haven't exceeded max attempts
        if pollAttempts < 20 && isAutoPolling { // Max 2 minutes (20 * 6 seconds)
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

#Preview {
    OnboardingGmailView()
        .environmentObject(OnboardingManager())
}
