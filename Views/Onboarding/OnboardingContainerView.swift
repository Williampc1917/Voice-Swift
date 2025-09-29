//  OnboardingContainerView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.
//  UPDATED: Added email style selection step

import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var onboarding: OnboardingManager
    @State private var currentStepIndex = 0
    
    // ← UPDATED: Now includes emailStyle step (4 total steps)
    private var allSteps: [OnboardingStep] = [.start, .profile, .gmail, .emailStyle]
    
    var body: some View {
        ZStack {
            AppBackground() // Design system background
            
            // Step content with smooth transitions
            Group {
                switch onboarding.step {
                case .start:
                    OnboardingWelcomeView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        
                case .profile:
                    OnboardingProfileView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        
                case .gmail:
                    OnboardingGmailView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                
                // ← NEW: Email style selection step
                case .emailStyle:
                    OnboardingEmailStyleView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        
                case .completed:
                    // If we somehow get to completed step while still in onboarding container,
                    // show the email style view (which will handle the transition out)
                    OnboardingEmailStyleView()
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.5), value: onboarding.step)
            
            // Progress indicator with white text
            VStack {
                HStack {
                    Spacer()
                    OnboardingProgressView(currentStep: onboarding.step)
                        .padding(.trailing, 20)
                        .padding(.top, 60)
                }
                Spacer()
            }
        }
        .alert("Error", isPresented: .constant(onboarding.errorMessage != nil)) {
            Button("OK") { onboarding.errorMessage = nil }
        } message: {
            Text(onboarding.errorMessage ?? "")
        }
    }
}

// MARK: - Updated Progress Indicator with Design System
struct OnboardingProgressView: View {
    let currentStep: OnboardingStep
    
    // ← UPDATED: Progress values for 4 steps
    private var progress: Float {
        switch currentStep {
        case .start: return 0.25        // 1/4
        case .profile: return 0.5       // 2/4
        case .gmail: return 0.75        // 3/4
        case .emailStyle: return 0.95   // 4/4 (almost complete, showing progress)
        case .completed: return 1.0     // 100%
        }
    }
    
    // ← UPDATED: Step numbers for 4 steps
    private var stepNumber: Int {
        switch currentStep {
        case .start: return 1
        case .profile: return 2
        case .gmail: return 3
        case .emailStyle: return 4      // ← NEW
        case .completed: return 4       // Show 4/4 when complete
        }
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Step counter with white text
            Text("\(stepNumber)/4")  // ← UPDATED: Now 4 steps total
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
            
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(width: 80)
                .scaleEffect(y: 0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(OnboardingManager())
}
