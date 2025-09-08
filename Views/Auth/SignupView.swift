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
        AppBackground()

        ScrollView {
          VStack(spacing: 16) {
            VStack(spacing: 6) {
              Text("Create account").font(.title.bold())
              Text("Use your email and a strong password")
                .font(.callout).foregroundStyle(.secondary)
            }
            .padding(.top, 12)

            // Card
            VStack(spacing: 14) {
              LabeledEmailField(icon: "envelope", placeholder: "Email", text: $email)
              LabeledSecureField(icon: "key.fill", placeholder: "Password", text: $password)

              // Rules (copy only; backend is source of truth)
              VStack(alignment: .leading, spacing: 4) {
                Text("Password must include:").font(.caption).bold()
                Group {
                  Text("• At least 8 characters")
                  Text("• One lowercase, one uppercase")
                  Text("• One number and one symbol")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
            }
            .appCardStyle()
            .padding(.horizontal, 20)

            Button {
              auth.signUp(email: email, password: password)
              dismiss()
            } label: {
              Text("Sign Up")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primary)
            .disabled(!meetsLocalMin)
            .opacity(meetsLocalMin ? 1 : 0.6)
            .padding(.horizontal, 20)
            .animation(.spring(duration: 0.25), value: meetsLocalMin)

            Color.clear.frame(height: 1).onAppear {
              if !prefilledEmail.isEmpty { email = prefilledEmail }
            }
          }
          .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close") { dismiss() }
            .tint(.primary) // default text color; keeps the single-accent rule intact
        }
      }
    }
    .presentationBackground(.regularMaterial)
  }
}

#Preview {
  NavigationStack { SignupView(prefilledEmail: "preview@example.com") }
    .environmentObject(AuthManager())
}
