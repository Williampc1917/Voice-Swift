//
//  OnboardingProfileView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.



//
//  OnboardingProfileView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.
//

import SwiftUI

struct OnboardingProfileView: View {
  @EnvironmentObject var onboarding: OnboardingManager
  @State private var name: String = ""

  private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

  var body: some View {
    ZStack {
      AppBackground()

      VStack(spacing: 24) {
        Spacer()

        // Title + subtitle
        VStack(spacing: 8) {
          Text("What’s your name?")
            .font(.title.bold())
            .multilineTextAlignment(.center)

          Text("We’ll personalize your experience.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        }

        // Input card
        VStack(spacing: 14) {
          TextField("Enter your name", text: $name)
            .textInputAutocapitalization(.words)
            .disableAutocorrection(true)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .appInputStyle()

          // Inline error
          if let error = onboarding.errorMessage {
            Text(error)
              .font(.footnote)
              .foregroundColor(.red)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 12)
          }
        }
        .appCardStyle()
        .padding(.horizontal, 20)

        Spacer()

        // Continue button
        Button {
          Task { await onboarding.submitDisplayName(name) }
        } label: {
          if onboarding.isLoading {
            ProgressView().tint(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
          } else {
            Label("Continue", systemImage: "arrow.right")
              .fontWeight(.semibold)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
          }
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.primary)
        .disabled(!isValid || onboarding.isLoading)
        .opacity(isValid ? 1 : 0.6)
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .animation(.spring(duration: 0.25), value: isValid)
        .animation(.spring(duration: 0.25), value: onboarding.isLoading)
      }
    }
  }
}

#Preview {
  OnboardingProfileView()
    .environmentObject({
      let mgr = OnboardingManager()
      mgr.errorMessage = "Something went wrong, please try again."
      return mgr
    }())
}
