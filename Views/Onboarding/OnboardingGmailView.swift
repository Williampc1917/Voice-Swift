//
//  OnboardingGmailView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/10/25.
//

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

          Text("We’re working on Gmail integration. This step isn’t functional yet — you’ll stop here for now.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        }

        Spacer()

        // Disabled/placeholder button
        Button {
          // For now: do nothing
          // Later: will trigger Gmail OAuth → backend → onboarding.complete
        } label: {
          Label("Connect Gmail", systemImage: "arrow.right")
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.gray) // gray to indicate disabled
        .disabled(true)
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
      }
    }
  }
}

#Preview {
  OnboardingGmailView()
    .environmentObject(OnboardingManager())
}
