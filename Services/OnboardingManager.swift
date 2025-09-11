//
//  OnboardingManager.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/9/25.
//

import Foundation
import SwiftUI

// MARK: - Clean Domain Models (UI-facing)
enum OnboardingStep {
    case start
    case profile
    case gmail
    case completed
}

extension OnboardingStep {
    init(from wire: WireOnboardingStep) {
        switch wire {
        case .start: self = .start
        case .profile: self = .profile
        case .gmail: self = .gmail
        case .completed: self = .completed
        }
    }
}

@MainActor
final class OnboardingManager: ObservableObject {
    @Published var needsOnboarding = false
    @Published var step: OnboardingStep = .start
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabaseSvc = SupabaseService()
    private let api = APIService()

    // MARK: - Check onboarding status
    func refreshStatus() async {
        await withLoading {
            let token = try await self.supabaseSvc.currentAccessToken()
            let status = try await self.api.getOnboardingStatus(accessToken: token)
            self.needsOnboarding = !status.onboardingCompleted
            self.step = OnboardingStep(from: status.step)
        }
    }

    // MARK: - Submit profile name
    func submitDisplayName(_ name: String) async {
        await withLoading {
            let token = try await self.supabaseSvc.currentAccessToken()
            _ = try await self.api.updateProfileName(
                accessToken: token,
                displayName: name,
                timezone: TimeZone.current.identifier
            )
            await self.refreshStatus()
        }
    }

    // MARK: - Utility wrapper
    private func withLoading(_ work: @escaping () async throws -> Void) async {
        self.isLoading = true
        self.errorMessage = nil
        do { try await work() }
        catch { self.errorMessage = error.localizedDescription }
        self.isLoading = false
    }
}
