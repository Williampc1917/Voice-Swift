//
//  SignupView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//

import SwiftUI

struct SignupView: View {
  @EnvironmentObject var auth: AuthManager
  @Environment(\.dismiss) var dismiss

  @State var prefilledEmail: String = ""
  @State private var email = ""
  @State private var password = ""

  // Local gate; Supabase enforces the real rules server-side
  private var meetsLocalMin: Bool { password.count >= 6 && email.contains("@") }

  var body: some View {
    NavigationStack {
      ZStack {
        AppBackground() // Dark professional background

        ScrollView {
          VStack(spacing: 36) {
            Spacer()

            // Header with white text
            VStack(spacing: 12) {
              Text("Create account")
                .font(.title.bold())
                .foregroundColor(.white)

              Text("Use your email and a strong password")
                .font(.callout)
                .foregroundColor(.white.opacity(0.85))
            }

            // Input fields using dark theme components
            VStack(spacing: 16) {
              LabeledEmailField(icon: "envelope", placeholder: "Email", text: $email)
              LabeledSecureField(icon: "key.fill", placeholder: "Password", text: $password)

              // Password rules with white text
              VStack(alignment: .leading, spacing: 6) {
                Text("Password must include:")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundColor(.white.opacity(0.85))

                Group {
                  Text("• At least 8 characters")
                  Text("• One lowercase, one uppercase")
                  Text("• One number and one symbol")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.top, 8)
            }
            .appCardStyle()
            .padding(.horizontal, 24)

            Spacer()

            // Sign up button with OnboardingProfileView styling
            Button {
              auth.signUp(email: email, password: password)
              dismiss()
            } label: {
              Text("Sign Up")
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
            .disabled(!meetsLocalMin)
            .opacity(meetsLocalMin ? 1 : 0.5)
            .padding(.horizontal, 24)
            .padding(.bottom, 44)
            .animation(.easeInOut(duration: 0.2), value: meetsLocalMin)

            Color.clear.frame(height: 1).onAppear {
              if !prefilledEmail.isEmpty { email = prefilledEmail }
            }
          }
        }
        .scrollDismissesKeyboard(.interactively)
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close") { dismiss() }
            .foregroundColor(.white.opacity(0.85))
        }
      }
    }
    .presentationBackground(.clear) // Let the dark background show through
  }
}

#Preview {
  NavigationStack { SignupView(prefilledEmail: "preview@example.com") }
    .environmentObject(AuthManager())
}
