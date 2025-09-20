//
//  ContentView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//

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
            print("🔍 [ContentView] needsOnboarding changed to: \(needsOnboarding)")
            print("🔍 [ContentView] Current transition view: \(transitions.currentView)")
            Task { await handleOnboardingChange(needsOnboarding) }
        }
        // 🔥 ADDED: Listen for step changes to catch backend-driven completion
        .onChange(of: onboarding.step) { step in
            print("🔍 [ContentView] step changed to: \(step)")
            print("🔍 [ContentView] Current transition view: \(transitions.currentView)")
            print("🔍 [ContentView] Current needsOnboarding: \(onboarding.needsOnboarding)")
            Task { await handleStepChange(step) }
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
        print("🔍 [ContentView] handleOnboardingChange called with needsOnboarding: \(needsOnboarding)")
        print("🔍 [ContentView] Current transitions.currentView: \(transitions.currentView)")
        print("🔍 [ContentView] Current step: \(onboarding.step)")
        
        // If onboarding is no longer needed, go to main app
        if !needsOnboarding && transitions.currentView == .onboarding {
            print("🔍 [ContentView] ✅ Onboarding no longer needed, transitioning to main app")
            await transitions.showMainApp()
            print("🔍 [ContentView] ✅ Transition to main app completed")
        } else {
            print("🔍 [ContentView] Not transitioning - needsOnboarding: \(needsOnboarding), currentView: \(transitions.currentView)")
        }
    }
    
    // 🔥 ADDED: Handle step changes to catch backend-driven completion
    private func handleStepChange(_ step: OnboardingStep) async {
        print("🔍 [ContentView] handleStepChange called with step: \(step)")
        print("🔍 [ContentView] Current needsOnboarding: \(onboarding.needsOnboarding)")
        print("🔍 [ContentView] Current transitions.currentView: \(transitions.currentView)")
        
        if step == .completed {
            print("🔍 [ContentView] ✅ Step is completed, transitioning to main app")
            await transitions.showMainApp()
            print("🔍 [ContentView] ✅ Transition to main app completed")
        } else {
            print("🔍 [ContentView] Step is not completed, staying in current view")
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
