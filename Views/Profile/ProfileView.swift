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
      AppBackground()

      VStack(spacing: 20) {
        if let p = auth.profile {
          // Profile Card
          VStack(spacing: 14) {
            // Simple avatar badge using initials
            Circle()
              .fill(.white.opacity(0.18))
              .frame(width: 72, height: 72)
              .overlay(
                Text(initials(from: p.displayName ?? p.email))
                  .font(.title2.weight(.semibold))
              )

            Text(p.displayName?.isEmpty == false ? p.displayName! : "User")
              .font(.title.bold())

            Text(p.email)
              .font(.callout)
              .foregroundStyle(.secondary)

            if let plan = p.plan {
              Text(plan.capitalized)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.2)))
            }
          }
          .frame(maxWidth: .infinity)
          .appCardStyle()
          .padding(.horizontal, 20)
          .transition(.scale.combined(with: .opacity))

          Button {
            auth.signOut()
          } label: {
            Text("Sign Out")
              .fontWeight(.semibold)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
          }
          .buttonStyle(.borderedProminent)
          .tint(AppTheme.primary)
          .padding(.horizontal, 20)
        } else {
          ProgressView("Loading profile…")
            .task { try? await auth.fetchProfile() }
        }

        Spacer(minLength: 10)
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
