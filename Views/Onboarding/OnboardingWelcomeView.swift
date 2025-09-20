//
//  OnboardingWelcomeView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.
//

import SwiftUI

struct OnboardingWelcomeView: View {
  @EnvironmentObject var onboarding: OnboardingManager
  @State private var animate = false

  var body: some View {
    ZStack {
      AppBackground() // Design system background

      VStack(spacing: 36) {
        Spacer()

        // App branding with white text
        VStack(spacing: 12) {
          Image(systemName: "waveform")
            .font(.system(size: 56, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundColor(.blue)
            .scaleEffect(animate ? 1.1 : 1.0)
            .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)
            .animation(
              .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
              value: animate
            )
            .onAppear { animate = true }

          Text("Welcome")
            .font(.largeTitle.bold())
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

          Text("Your voice, your inbox — let's get started.")
            .font(.callout)
            .foregroundColor(.white.opacity(0.85))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        }

        Spacer()

        // Continue button using design system
        Button {
          onboarding.step = .profile
        } label: {
          Label("Get Started", systemImage: "arrow.right")
        }
        .appButtonStyle()
        .padding(.horizontal, 24)
        .padding(.bottom, 44)
      }
    }
  }
}

#Preview {
  OnboardingWelcomeView()
    .environmentObject(OnboardingManager())
}
