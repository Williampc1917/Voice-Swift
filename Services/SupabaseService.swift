//
//  SupabaseService.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//

import Foundation
import Supabase

// Shared global client
let supabase = SupabaseClient(
    supabaseURL: AppConfig.supabaseURL,
    supabaseKey: AppConfig.supabaseAnonKey
)

struct SupabaseService {
    func signUp(email: String, password: String) async throws {
        _ = try await supabase.auth.signUp(email: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        _ = try await supabase.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
    }

    func currentAccessToken() async throws -> String {
        let session = try await supabase.auth.session
        return session.accessToken
    }
}
