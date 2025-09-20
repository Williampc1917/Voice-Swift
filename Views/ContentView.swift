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
      // Use the new design system background
      AppBackground()

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

      // Overlay transition indicator
      if transitions.isTransitioning {
        Color.black.opacity(0.15)
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
    .onChange(of: onboarding.step) { step in
      if transitions.currentView == .onboarding {
        Task { await handleStepChange(step) }
      }
    }
  }

  // MARK: - Flow Control
  private func handleAppFlow() async {
    await transitions.transition(to: .loading, message: "Loading your session...")

    while auth.isRestoringSession {
      try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec
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
    await onboarding.refreshStatus()

    if onboarding.needsOnboarding {
      await transitions.showOnboarding()
    } else {
      await transitions.showMainApp()
    }
  }

  private func handleOnboardingChange(_ needsOnboarding: Bool) async {
    if !needsOnboarding && transitions.currentView == .onboarding {
      await transitions.showMainApp()
    }
  }

  private func handleStepChange(_ step: OnboardingStep) async {
    if step == .completed &&
       !onboarding.needsOnboarding &&
       transitions.currentView == .onboarding {
      await transitions.showMainApp()
    }
  }
}

// MARK: - Supporting Views with OnboardingProfileView Styling

struct LoadingView: View {
  let message: String
  @State private var animationPhase = 0.0

  var body: some View {
    VStack(spacing: 24) {
      // Icon with same styling as OnboardingProfileView
      Image(systemName: "waveform")
        .font(.system(size: 50, weight: .semibold))
        .symbolRenderingMode(.hierarchical)
        .foregroundColor(.blue)
        .scaleEffect(1.0 + sin(animationPhase) * 0.08)
        .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animationPhase)
        .onAppear { animationPhase = 1.0 }

      Text(message)
        .font(.callout)
        .foregroundColor(.white.opacity(0.85))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
    }
    .padding(24)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.white.opacity(0.05))
        .overlay(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    )
    .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
    .padding(.horizontal, 24)
    .transition(.scale.combined(with: .opacity))
  }
}

struct OnboardingCheckView: View {
  @State private var rotationAngle = 0.0

  var body: some View {
    VStack(spacing: 24) {
      // Custom animated loading indicator with OnboardingProfileView styling
      ZStack {
        Circle()
          .stroke(Color.white.opacity(0.2), lineWidth: 3)
          .frame(width: 50, height: 50)
        
        Circle()
          .trim(from: 0, to: 0.7)
          .stroke(
            LinearGradient(
              colors: [Color.blue, Color.blue.opacity(0.3)],
              startPoint: .leading,
              endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
          )
          .frame(width: 50, height: 50)
          .rotationEffect(.degrees(rotationAngle))
          .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: rotationAngle)
          .onAppear { rotationAngle = 360 }
      }
      .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)

      Text("Setting up your account...")
        .font(.callout)
        .foregroundColor(.white.opacity(0.85))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
    }
    .padding(24)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.white.opacity(0.05))
        .overlay(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    )
    .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
    .padding(.horizontal, 24)
    .transition(.scale.combined(with: .opacity))
  }
}

#Preview {
  ContentView()
    .environmentObject(AuthManager())
}
