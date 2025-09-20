//
//  OnboardingContainerView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.
//
import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var onboarding: OnboardingManager
    @State private var currentStepIndex = 0
    
    private var allSteps: [OnboardingStep] = [.start, .profile, .gmail, .completed]
    
    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()
            
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
                        
                case .completed:
                    OnboardingCompleteView()
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.5), value: onboarding.step)
            
            // Progress indicator
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

// MARK: - Progress Indicator
struct OnboardingProgressView: View {
    let currentStep: OnboardingStep
    
    private var progress: Float {
        switch currentStep {
        case .start: return 0.25
        case .profile: return 0.5
        case .gmail: return 0.75
        case .completed: return 1.0
        }
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Step counter
            Text("\(Int(progress * 4))/4")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.primary))
                .frame(width: 80)
                .scaleEffect(y: 0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(OnboardingManager())
}
