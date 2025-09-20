//
//  OnboardingGmailView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.
//

import SwiftUI

struct OnboardingGmailView: View {
    @EnvironmentObject var onboarding: OnboardingManager

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 24) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 56, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppTheme.primary)

                    Text("Connect Gmail")
                        .font(.title.bold())

                    Text("Link your Gmail account so you can use voice features to manage email.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Main content area
                VStack(spacing: 20) {
                    
                    // Processing state (when OAuth is completing in background)
                    if onboarding.isProcessingOAuth {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Completing Gmail connection...")
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
                                
                                Text("Gmail Connected Successfully!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                                
                                Text("You can now use voice features to manage your email.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .appCardStyle()
                            .padding(.horizontal, 20)
                            
                            // Continue button - goes directly to ProfileView
                            Button {
                                Task {
                                    // Direct transition to ProfileView, skip OnboardingCompleteView
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
                            Button("Disconnect Gmail") {
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
                    
                    // Initial state (ready to connect) OR returned from Safari but state not updated
                    else {
                        VStack(spacing: 16) {
                            // Main connect button
                            Button {
                                Task { await onboarding.startGmailAuth() }
                            } label: {
                                if onboarding.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                } else {
                                    Label("Connect Gmail", systemImage: "arrow.right")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.primary)
                            .disabled(onboarding.isLoading)
                            .padding(.horizontal, 20)
                            
                            // Refresh button (for users returning from Safari)
                            VStack(spacing: 8) {
                                Text("Just completed Gmail authentication in Safari?")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button {
                                    Task {
                                        await onboarding.completeGmailAuthIfPending()
                                        await onboarding.refreshStatus()
                                        
                                        // 🔥 FIXED: If Gmail connected and onboarding complete, skip OnboardingCompleteView
                                        if onboarding.gmailConnected && !onboarding.needsOnboarding {
                                            // Direct transition without showing OnboardingCompleteView
                                            onboarding.needsOnboarding = false
                                        }
                                    }
                                } label: {
                                    if onboarding.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Label("Check Connection Status", systemImage: "arrow.clockwise")
                                            .font(.footnote)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(.secondary)
                                .disabled(onboarding.isLoading)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        // Auto-process OAuth when user returns from Safari (but don't rely on it)
        .onAppear {
            // Only auto-process if there's pending OAuth and we're not already processing
            if UserDefaults.standard.string(forKey: "gmail_oauth_state") != nil &&
               !onboarding.isProcessingOAuth &&
               !onboarding.gmailConnected {
                Task {
                    // Small delay to let the view settle
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await onboarding.completeGmailAuthIfPending()
                }
            }
        }
    }
}
