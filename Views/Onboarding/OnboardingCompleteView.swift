//
//  OnboardingCompleteView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.


import SwiftUI

struct OnboardingCompleteView: View {
    @EnvironmentObject var onboarding: OnboardingManager
    @State private var showContent = false
    @State private var showButton = false
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Success animation
                VStack(spacing: 20) {
                    // Animated checkmark
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .scaleEffect(showContent ? 1.0 : 0.5)
                            .opacity(showContent ? 1 : 0)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.green)
                            .scaleEffect(showContent ? 1.0 : 0.5)
                            .opacity(showContent ? 1 : 0)
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                    
                    // Success text
                    VStack(spacing: 12) {
                        Text("All set! 🎉")
                            .font(.title.bold())
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                        
                        Text("Enjoy the app.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                    }
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: showContent)
                }
                
                Spacer()
                
                // Exit button with delayed appearance
                if showButton {
                    Button {
                        // Smooth exit with haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            onboarding.needsOnboarding = false
                        }
                    } label: {
                        HStack {
                            Text("Start Using App")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            // Staggered animations
            withAnimation {
                showContent = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showButton = true
                }
            }
        }
    }
}

#Preview {
    OnboardingCompleteView()
        .environmentObject(OnboardingManager())
}
