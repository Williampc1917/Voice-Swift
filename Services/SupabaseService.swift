//
//  SupabaseService.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.


import Foundation
import Supabase

// Shared global client
let supabase = SupabaseClient(
    supabaseURL: AppConfig.supabaseURL,
    supabaseKey: AppConfig.supabaseAnonKey
)

// MARK: - Enhanced Error Types
enum AuthError: Error, LocalizedError {
    case noSession
    case tokenExpired
    case refreshFailed
    case networkError
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noSession:
            return "No active session. Please sign in again."
        case .tokenExpired:
            return "Your session has expired. Please sign in again."
        case .refreshFailed:
            return "Failed to refresh session. Please sign in again."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .unknownError(let error):
            return "Authentication error: \(error.localizedDescription)"
        }
    }
}

struct SupabaseService {
    
    // MARK: - Authentication Methods
    func signUp(email: String, password: String) async throws {
        do {
            _ = try await supabase.auth.signUp(email: email, password: password)
        } catch {
            print("[SupabaseService] Sign up failed: \(error)")
            throw AuthError.unknownError(error)
        }
    }

    func signIn(email: String, password: String) async throws {
        do {
            _ = try await supabase.auth.signIn(email: email, password: password)
        } catch {
            print("[SupabaseService] Sign in failed: \(error)")
            throw AuthError.unknownError(error)
        }
    }

    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
        } catch {
            print("[SupabaseService] Sign out failed: \(error)")
            throw AuthError.unknownError(error)
        }
    }

    // MARK: - Enhanced Token Management
    func currentAccessToken() async throws -> String {
        do {
            let session = try await supabase.auth.session
            
            // Check if token is close to expiring (refresh if < 5 minutes left)
            let expiresAt = Date(timeIntervalSince1970: TimeInterval(session.expiresAt))
            let fiveMinutesFromNow = Date().addingTimeInterval(300)
            
            if expiresAt < fiveMinutesFromNow {
                print("[SupabaseService] Token expires soon, refreshing...")
                let refreshedSession = try await supabase.auth.refreshSession()
                return refreshedSession.accessToken
            }
            
            return session.accessToken
            
        } catch {
            print("[SupabaseService] Token retrieval/refresh failed: \(error)")
            
            // Try to determine the specific error type
            if error.localizedDescription.contains("refresh_token_not_found") {
                throw AuthError.tokenExpired
            } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                throw AuthError.networkError
            } else {
                throw AuthError.refreshFailed
            }
        }
    }
    
    // MARK: - Session Management
    func hasValidSession() async -> Bool {
        do {
            _ = try await supabase.auth.session
            return true
        } catch {
            print("[SupabaseService] No valid session: \(error)")
            return false
        }
    }
    
    func getCurrentUser() async throws -> User? {
        do {
            let session = try await supabase.auth.session
            return session.user
        } catch {
            print("[SupabaseService] Failed to get current user: \(error)")
            throw AuthError.noSession
        }
    }
    
    // MARK: - Manual Refresh
    func refreshSession() async throws -> Session {
        do {
            print("[SupabaseService] Manually refreshing session...")
            let session = try await supabase.auth.refreshSession()
            print("[SupabaseService] Session refreshed successfully")
            return session
        } catch {
            print("[SupabaseService] Manual session refresh failed: \(error)")
            throw AuthError.refreshFailed
        }
    }
}
