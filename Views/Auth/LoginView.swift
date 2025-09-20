//
//  LoginView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//

import SwiftUI

struct LoginView: View {
  @EnvironmentObject var auth: AuthManager
  @State private var email = ""
  @State private var password = ""
  @State private var showSignup = false

  private var isValid: Bool { email.contains("@") && password.count >= 6 }

  var body: some View {
    ZStack {
      AppBackground() // Now uses the dark professional gradient

      ScrollView {
        VStack(spacing: 36) {
          Spacer()

          // Heading with white text for dark background
          VStack(spacing: 12) {
            Image(systemName: "lock.shield")
              .font(.system(size: 50, weight: .semibold))
              .symbolRenderingMode(.hierarchical)
              .foregroundColor(.blue)
              .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)

            Text("Welcome back")
              .font(.title.bold())
              .foregroundColor(.white)

            Text("Sign in to continue")
              .font(.callout)
              .foregroundColor(.white.opacity(0.85))
          }

          // Input fields using dark theme components
          VStack(spacing: 16) {
            LabeledEmailField(icon: "envelope", placeholder: "Email", text: $email)
            LabeledSecureField(icon: "key.fill", placeholder: "Password", text: $password)

            HStack {
              Spacer()
              Button("Forgot password?") { /* wire later */ }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
                .buttonStyle(.plain)
            }
          }
          .appCardStyle()
          .padding(.horizontal, 24)

          Spacer()

          // Sign in button with OnboardingProfileView styling
          Button {
            auth.signIn(email: email, password: password)
          } label: {
            HStack {
              if auth.isLoading {
                ProgressView().tint(.white)
              }
              Text(auth.isLoading ? "Signing in…" : "Sign In")
                .font(.system(size: 18, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
          }
          .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(Color.blue)
              .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)
          )
          .foregroundColor(.white)
          .disabled(!isValid || auth.isLoading)
          .opacity(isValid ? 1 : 0.5)
          .padding(.horizontal, 24)
          .animation(.easeInOut(duration: 0.2), value: isValid)
          .animation(.easeInOut(duration: 0.2), value: auth.isLoading)

          // Go to signup with white text
          Button {
            showSignup = true
          } label: {
            Text("Create an account")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.white.opacity(0.85))
              .padding(.vertical, 14)
              .padding(.horizontal, 32)
              .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                  .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
              )
          }
          .buttonStyle(.plain)
          .padding(.bottom, 44)
        }
      }
      .scrollDismissesKeyboard(.interactively)
    }
    .sheet(isPresented: $showSignup) {
      SignupView(prefilledEmail: email)
        .presentationDetents([.large])
        .presentationCornerRadius(20)
    }
  }
}

#Preview {
  NavigationStack { LoginView() }
    .environmentObject(AuthManager())
}
