//
//  OnboardingContainerView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.
//

//
//  OnboardingContainerView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.
//

import SwiftUI

struct OnboardingContainerView: View {
  @EnvironmentObject var onboarding: OnboardingManager

  var body: some View {
    ZStack {
      AppBackground().ignoresSafeArea()

      switch onboarding.step {
      case .start:
        OnboardingWelcomeView()

      case .profile:
        OnboardingProfileView()

      case .gmail:
        OnboardingGmailView()

      case .completed:
        OnboardingCompleteView()
      }
    }
    .alert("Error", isPresented: .constant(onboarding.errorMessage != nil)) {
      Button("OK") { onboarding.errorMessage = nil }
    } message: {
      Text(onboarding.errorMessage ?? "")
    }
  }
}

#Preview {
  OnboardingContainerView()
    .environmentObject(OnboardingManager())
}
