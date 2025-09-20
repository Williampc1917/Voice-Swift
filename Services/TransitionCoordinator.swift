//
//  TransitionCoordinator.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/19/25.
//

// TransitionCoordinator.swift - Add this new file

import SwiftUI

@MainActor
final class TransitionCoordinator: ObservableObject {
    @Published var currentView: AppView = .loading
    @Published var isTransitioning = false
    @Published var loadingMessage = "Loading..."
    
    enum AppView: CaseIterable {
        case loading
        case auth
        case onboardingCheck
        case onboarding
        case mainApp
        
        var id: String {
            switch self {
            case .loading: return "loading"
            case .auth: return "auth"
            case .onboardingCheck: return "onboardingCheck"
            case .onboarding: return "onboarding"
            case .mainApp: return "mainApp"
            }
        }
    }
    
    // MARK: - Smooth Transitions
    func transition(to newView: AppView, message: String? = nil, delay: TimeInterval = 0.3) async {
        guard currentView != newView else { return }
        
        isTransitioning = true
        if let message = message {
            loadingMessage = message
        }
        
        // Smooth transition delay
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        withAnimation(.easeInOut(duration: 0.4)) {
            currentView = newView
        }
        
        // Brief moment to show new view before removing transition state
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        isTransitioning = false
    }
    
    // MARK: - Specific Transition Methods
    func showAuth() async {
        await transition(to: .auth, message: "Welcome back")
    }
    
    func showOnboardingCheck() async {
        await transition(to: .onboardingCheck, message: "Setting up your account...")
    }
    
    func showOnboarding() async {
        await transition(to: .onboarding, message: "Let's get started")
    }
    
    func showMainApp() async {
        await transition(to: .mainApp, message: "Welcome!")
    }
}
