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
      AppBackground()

      ScrollView {
        VStack(spacing: 24) {
          // Heading
          VStack(spacing: 8) {
            Image(systemName: "lock.shield")
              .font(.system(size: 44, weight: .semibold))
              .symbolRenderingMode(.hierarchical)
            Text("Welcome back")
              .font(.largeTitle.weight(.bold))
            Text("Sign in to continue")
              .font(.callout)
              .foregroundStyle(.secondary)
          }
          .padding(.top, 24)

          // Card with inputs
          VStack(spacing: 14) {
            LabeledEmailField(icon: "envelope", placeholder: "Email", text: $email)
            LabeledSecureField(icon: "key.fill", placeholder: "Password", text: $password)

            HStack {
              Spacer()
              Button("Forgot password?") { /* wire later */ }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
          }
          .appCardStyle()
          .padding(.horizontal, 20)

          // Sign in button
          Button {
            auth.signIn(email: email, password: password)
          } label: {
            HStack {
              if auth.isLoading { ProgressView().tint(.white) }
              Text(auth.isLoading ? "Signing in…" : "Sign In")
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
          }
          .buttonStyle(.borderedProminent)
          .tint(AppTheme.primary)
          .disabled(!isValid || auth.isLoading)
          .opacity((!isValid || auth.isLoading) ? 0.7 : 1)
          .padding(.horizontal, 20)
          .animation(.spring(duration: 0.25), value: isValid)
          .animation(.spring(duration: 0.25), value: auth.isLoading)

          // Go to signup
          Button {
            showSignup = true
          } label: {
            Text("Create an account").fontWeight(.semibold)
          }
          .buttonStyle(.bordered)
          .tint(.primary) // neutral text button to keep single accent color usage
          .padding(.bottom, 40)
        }
      }
      .scrollDismissesKeyboard(.interactively)
    }
    .sheet(isPresented: $showSignup) {
      SignupView(prefilledEmail: email)
        .presentationDetents([.large])   // always full height
        .presentationCornerRadius(20)
    }
  }
}

#Preview {
  NavigationStack { LoginView() }
    .environmentObject(AuthManager())
}
