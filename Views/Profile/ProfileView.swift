//
//  ProfileView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//

import SwiftUI

struct ProfileView: View {
  @EnvironmentObject var auth: AuthManager

  var body: some View {
    ZStack {
      AppBackground() // Dark professional gradient

      VStack(spacing: 36) {
        Spacer()

        if let p = auth.profile {
          // Profile Card with OnboardingProfileView styling
          VStack(spacing: 20) {
            // Avatar with improved styling
            Circle()
              .fill(Color.white.opacity(0.1))
              .frame(width: 80, height: 80)
              .overlay(
                Text(initials(from: p.displayName ?? p.email))
                  .font(.title.weight(.semibold))
                  .foregroundColor(.white)
              )
              .overlay(
                Circle()
                  .strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
              )
              .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

            VStack(spacing: 8) {
              Text(p.displayName?.isEmpty == false ? p.displayName! : "User")
                .font(.title.bold())
                .foregroundColor(.white)

              Text(p.email)
                .font(.callout)
                .foregroundColor(.white.opacity(0.85))

              if let plan = p.plan {
                Text(plan.capitalized)
                  .font(.footnote.weight(.semibold))
                  .foregroundColor(.white.opacity(0.9))
                  .padding(.horizontal, 12)
                  .padding(.vertical, 6)
                  .background(
                    Capsule()
                      .fill(Color.white.opacity(0.1))
                      .overlay(
                        Capsule()
                          .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                      )
                  )
                  .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
              }
            }
          }
          .padding(24)
          .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(Color.white.opacity(0.05))
              .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                  .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
              )
          )
          .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
          .padding(.horizontal, 24)
          .transition(.scale.combined(with: .opacity))

          Spacer()

          // Sign out button with OnboardingProfileView styling
          Button {
            auth.signOut()
          } label: {
            Text("Sign Out")
              .font(.system(size: 18, weight: .semibold))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
          }
          .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(Color.blue)
              .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)
          )
          .foregroundColor(.white)
          .padding(.horizontal, 24)
          .padding(.bottom, 44)

        } else {
          // Loading state with OnboardingProfileView styling
          VStack(spacing: 20) {
            ProgressView()
              .scaleEffect(1.2)
              .tint(.blue)

            Text("Loading profile...")
              .font(.callout)
              .foregroundColor(.white.opacity(0.85))
          }
          .padding(24)
          .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(Color.white.opacity(0.05))
              .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                  .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
              )
          )
          .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
          .padding(.horizontal, 24)
          .task { try? await auth.fetchProfile() }
        }
      }
    }
  }

  private func initials(from text: String) -> String {
    let parts = text.split(separator: " ")
    if let first = parts.first?.first, let last = parts.dropFirst().first?.first {
      return "\(first)\(last)".uppercased()
    }
    return String(text.prefix(1)).uppercased()
  }
}

#Preview {
  ProfileView()
    .environmentObject({
      let mock = AuthManager()
      mock.profile = UserProfile(
        id: "1",
        email: "jane@example.com",
        displayName: "Jane Doe",
        plan: "Pro"
      )
      mock.isAuthenticated = true
      return mock
    }())
}
