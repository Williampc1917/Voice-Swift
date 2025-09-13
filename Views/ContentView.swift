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

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var auth: AuthManager
  @StateObject private var onboarding = OnboardingManager()
  @State private var showSlowRestore = false
  @State private var checkedOnboarding = false   // new flag

  var body: some View {
    Group {
      if auth.isRestoringSession {
        // Session restore (spinner on gradient)
        ZStack {
          AppBackground().ignoresSafeArea()

          if showSlowRestore {
            VStack(spacing: 8) {
              ProgressView()
              Text("Loading your session…")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
        }
        .onAppear { armSlowRestoreTimer() }
        .onChange(of: auth.isRestoringSession) { isRestoring in
          if isRestoring {
            showSlowRestore = false
            armSlowRestoreTimer()
          } else {
            showSlowRestore = false
          }
        }

      } else if auth.isAuthenticated {
        if !checkedOnboarding {
          // 👇 FIX: background added here
          ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 8) {
              ProgressView()
              Text("Checking your account…")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
          .task {
            await onboarding.refreshStatus()
            checkedOnboarding = true
          }

        } else if onboarding.needsOnboarding || onboarding.step == .completed {
          OnboardingContainerView()
            .environmentObject(onboarding)

        } else {
          ProfileView()
        }

      } else {
        LoginView()
      }
    }
    .alert("Error", isPresented: .constant(auth.errorMessage != nil)) {
      Button("OK") { auth.errorMessage = nil }
    } message: { Text(auth.errorMessage ?? "") }
  }

  private func armSlowRestoreTimer() {
    Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
      if auth.isRestoringSession {
        await MainActor.run { showSlowRestore = true }
      }
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(AuthManager())
}
