//
//  ContentView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//


import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var onboarding = OnboardingManager()
    @StateObject private var transitions = TransitionCoordinator()
    
    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()
            
            // Main content with smooth transitions
            Group {
                switch transitions.currentView {
                case .loading:
                    LoadingView(message: transitions.loadingMessage)
                        .transition(.opacity)
                    
                case .auth:
                    LoginView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                case .onboardingCheck:
                    OnboardingCheckView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                case .onboarding:
                    OnboardingContainerView()
                        .environmentObject(onboarding)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                case .mainApp:
                    ProfileView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: transitions.currentView)
            
            // Overlay transition indicator if needed
            if transitions.isTransitioning {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .alert("Error", isPresented: .constant(auth.errorMessage != nil)) {
            Button("OK") { auth.errorMessage = nil }
        } message: {
            Text(auth.errorMessage ?? "")
        }
        .task {
            await handleAppFlow()
        }
        .onChange(of: auth.isAuthenticated) { isAuth in
            Task { await handleAuthChange(isAuth) }
        }
        .onChange(of: onboarding.needsOnboarding) { needsOnboarding in
            Task { await handleOnboardingChange(needsOnboarding) }
        }
    }
    
    // MARK: - Flow Control
    private func handleAppFlow() async {
        // Initial app launch flow
        await transitions.transition(to: .loading, message: "Loading your session...")
        
        // Wait for auth restoration
        while auth.isRestoringSession {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        if auth.isAuthenticated {
            await handleAuthenticatedUser()
        } else {
            await transitions.showAuth()
        }
    }
    
    private func handleAuthChange(_ isAuthenticated: Bool) async {
        if isAuthenticated {
            await handleAuthenticatedUser()
        } else {
            await transitions.showAuth()
        }
    }
    
    private func handleAuthenticatedUser() async {
        await transitions.showOnboardingCheck()
        
        // Check onboarding status
        await onboarding.refreshStatus()
        
        if onboarding.needsOnboarding {
            await transitions.showOnboarding()
        } else {
            await transitions.showMainApp()
        }
    }
    
    private func handleOnboardingChange(_ needsOnboarding: Bool) async {
        // Only transition if we're currently in onboarding
        if transitions.currentView == .onboarding && !needsOnboarding {
            await transitions.showMainApp()
        }
    }
}

// MARK: - Supporting Views

struct LoadingView: View {
    let message: String
    @State private var animationPhase = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            // Animated logo/icon
            Image(systemName: "waveform")
                .font(.system(size: 48, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppTheme.primary)
                .scaleEffect(1.0 + sin(animationPhase) * 0.1)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animationPhase)
                .onAppear { animationPhase = 1.0 }
            
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .transition(.scale.combined(with: .opacity))
    }
}

struct OnboardingCheckView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Setting up your account...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
