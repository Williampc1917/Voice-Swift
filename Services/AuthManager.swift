//
//  AuthManager.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//
//
//  AuthManager.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//

//
//  AuthManager.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//

import Foundation
import SwiftUI
import Supabase

@MainActor
final class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false        // for buttons & API calls
    @Published var isRestoringSession = true // new: app startup check
    @Published var errorMessage: String?
    @Published var profile: UserProfile?

    private let supabaseSvc = SupabaseService()
    private let api = APIService()

    init() {
        Task { await restoreSession() }
        Task { await listenToAuth() }
    }

  func signIn(email: String, password: String) {
    Task {
      await self.withLoading {
        try await self.supabaseSvc.signIn(email: email, password: password)
        try await self.fetchProfile()
      }
    }
  }

  func signUp(email: String, password: String) {
    Task {
      await self.withLoading {
        _ = try await self.supabaseSvc.signUp(email: email, password: password)
        // If email confirmation is ON, there may be no session yet.
        self.errorMessage = "Check your email to confirm your account before logging in."
      }
    }
  }

  func signOut() {
    Task {
      await self.withLoading {
        try await self.supabaseSvc.signOut()
        self.profile = nil
        self.isAuthenticated = false
      }
    }
  }

  func fetchProfile() async throws {
    let token = try await self.supabaseSvc.currentAccessToken() // refreshes if needed
    let p = try await self.api.getUserProfile(accessToken: token)
    self.profile = p
    self.isAuthenticated = true
  }

  /// Only nudges Supabase to load/refresh its saved session; the listener decides UI.
    private func restoreSession() async {
            defer { self.isRestoringSession = false } // turn off at the end
            if let session = try? await supabase.auth.session {
                self.isAuthenticated = (session.user != nil)
                if isAuthenticated {
                    try? await fetchProfile()
                }
            } else {
                self.isAuthenticated = false
            }
        }

  /// React to all auth lifecycle events, including `.initialSession`.
  private func listenToAuth() async {
    await supabase.auth.onAuthStateChange { [weak self] event, _ in
      guard let self else { return }
      Task { @MainActor in
        switch event {
        case .initialSession:
          if (try? await self.supabaseSvc.currentAccessToken()) != nil {
            try? await self.fetchProfile()
          } else {
            self.isAuthenticated = false
          }
          self.isRestoringSession = false

        case .signedIn, .tokenRefreshed:
          try? await self.fetchProfile()
          self.isRestoringSession = false

        case .signedOut:
          self.profile = nil
          self.isAuthenticated = false
          self.isRestoringSession = false

        default:
          break
        }
      }
    }
  }

  private func withLoading(_ work: @escaping () async throws -> Void) async {
    self.isLoading = true
    self.errorMessage = nil
    do { try await work() }
    catch { self.errorMessage = error.localizedDescription }
    self.isLoading = false
  }
}
