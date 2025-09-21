//
//  OnboardingProfileView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/20/25.
//

import SwiftUI

struct OnboardingProfileView: View {
  @EnvironmentObject var onboarding: OnboardingManager
  @State private var name: String = ""
  @FocusState private var isFocused: Bool

  private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

  var body: some View {
    ZStack {
      AppBackground() // This now uses the dark professional gradient

      VStack(spacing: 36) {
        Spacer()

        // Title + subtitle
        VStack(spacing: 10) {
            Text("What's your name?")
            .font(.title.bold())
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

          Text("Your assistant will use this name when speaking with you.")
            .font(.callout)
            .foregroundColor(.white.opacity(0.85))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        }

        // Input field
        VStack(spacing: 8) {
          HStack(spacing: 10) {
            Image(systemName: "person.crop.circle")
              .foregroundStyle(.white.opacity(0.6))

            TextField("", text: $name)
              .focused($isFocused)
              .textInputAutocapitalization(.words)
              .disableAutocorrection(true)
              .textFieldStyle(.plain)
              .foregroundColor(.white)
              .placeholder(when: name.isEmpty) {
                Text("Enter your preferred name")
                  .foregroundColor(.white.opacity(0.4))
                  .font(.subheadline)
              }
          }
          .padding(16)
          .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(Color.white.opacity(0.05))
              .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                  .strokeBorder(isFocused ? Color.blue : Color.white.opacity(0.15), lineWidth: 1)
              )
          )
          .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

          // Modern inline error
          if let error = onboarding.errorMessage {
            HStack(spacing: 6) {
              Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red.opacity(0.85))
              Text(error)
                .font(.caption)
                .foregroundColor(.red.opacity(0.85))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(.easeInOut(duration: 0.2), value: onboarding.errorMessage)
          }
        }
        .padding(.horizontal, 24)

        Spacer()

        // Continue button
        Button {
          Task { await onboarding.submitDisplayName(name) }
        } label: {
          if onboarding.isLoading {
            ProgressView()
              .tint(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
          } else {
            Label("Continue", systemImage: "arrow.right")
              .font(.system(size: 18, weight: .semibold))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
          }
        }
        .background(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.blue) // single confident accent
            .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)
        )
        .foregroundColor(.white)
        .disabled(!isValid || onboarding.isLoading)
        .opacity(isValid ? 1 : 0.5)
        .padding(.horizontal, 24)
        .padding(.bottom, 44)
        .animation(.easeInOut(duration: 0.2), value: isValid)
        .animation(.easeInOut(duration: 0.2), value: onboarding.isLoading)
      }
      .frame(maxHeight: .infinity, alignment: .center)
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
