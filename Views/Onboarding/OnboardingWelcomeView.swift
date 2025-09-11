//
//  OnboardingWelcomeView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.
//

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
      AppBackground()

      VStack(spacing: 24) {
        Spacer()

        // App branding
        VStack(spacing: 12) {
          Image(systemName: "waveform") // could also try "mic.fill"
            .font(.system(size: 56, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(AppTheme.primary)
            .scaleEffect(animate ? 1.1 : 1.0) // breathing effect
            .animation(
              .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
              value: animate
            )
            .onAppear { animate = true }

          Text("Welcome")
            .font(.largeTitle.bold())
            .multilineTextAlignment(.center)

          Text("Your voice, your inbox — let’s get started.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        }

        Spacer()

        // Continue button
        Button {
          onboarding.step = .profile
        } label: {
          Label("Get Started", systemImage: "arrow.right")
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.primary)
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
      }
    }
  }
}

#Preview {
  OnboardingWelcomeView()
    .environmentObject(OnboardingManager())
}
