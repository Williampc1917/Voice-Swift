//
//  ContentView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var auth: AuthManager
  @State private var showSlowRestore = false

  var body: some View {
    Group {
      if auth.isRestoringSession {
        // Matches the launch brand color so it looks continuous
        ZStack {
          // Use your app background—if you prefer a plain color, replace with:
          // Color("LaunchBackground").ignoresSafeArea()
          AppBackground().ignoresSafeArea()

          // Only show a spinner if restore takes unusually long (>2s)
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
        ProfileView()
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
  ContentView().environmentObject(AuthManager())
}
