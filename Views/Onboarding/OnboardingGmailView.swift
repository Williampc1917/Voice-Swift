//
//  OnboardingGmailView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.
//

import SwiftUI

struct OnboardingGmailView: View {
  @EnvironmentObject var onboarding: OnboardingManager

  var body: some View {
    ZStack {
      AppBackground()

      VStack(spacing: 24) {
        Spacer()

        VStack(spacing: 12) {
          Image(systemName: "envelope.badge")
            .font(.system(size: 56, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(AppTheme.primary)

          Text("Connect Gmail")
            .font(.title.bold())

          if onboarding.gmailConnected {
            Text("✅ Your Gmail account is connected!")
              .font(.callout)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)
          } else {
            Text("Link your Gmail account so you can use voice features to manage email.")
              .font(.callout)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)
          }
        }

        Spacer()

        if onboarding.isLoading {
          ProgressView()
            .progressViewStyle(.circular)
            .padding(.bottom, 40)
        } else {
          if onboarding.gmailConnected {
            Button {
              Task { await onboarding.disconnectGmail() }
            } label: {
              Label("Disconnect Gmail", systemImage: "xmark.circle")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)

          } else {
            Button {
              Task {
                // 👇 Kick off OAuth flow
                await onboarding.startGmailAuth()
              }
            } label: {
              Label("Connect Gmail", systemImage: "arrow.right")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primary)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
          }
        }
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
  OnboardingGmailView()
    .environmentObject(OnboardingManager())
}
