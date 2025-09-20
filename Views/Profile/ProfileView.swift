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
      AppBackground() // FROM DESIGN SYSTEM

      VStack(spacing: 36) {
        Spacer()

        if let p = auth.profile {
          // Profile content using design system
          VStack(spacing: 20) {
            // Avatar
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
              }
            }
          }
          .appCardStyle() // FROM DESIGN SYSTEM
          .padding(.horizontal, 24)

          Spacer()

          // Sign out button using design system
          Button {
            auth.signOut()
          } label: {
            Text("Sign Out")
          }
          .appButtonStyle() // FROM DESIGN SYSTEM
          .padding(.horizontal, 24)
          .padding(.bottom, 44)

        } else {
          // Loading state using design system
          VStack(spacing: 20) {
            ProgressView()
              .scaleEffect(1.2)
              .tint(.blue)

            Text("Loading profile...")
              .font(.callout)
              .foregroundColor(.white.opacity(0.85))
          }
          .appCardStyle() // FROM DESIGN SYSTEM
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
