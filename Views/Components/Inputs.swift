//
//  Inputs.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/8/25.
//

import SwiftUI

// MARK: - Design System (Based on OnboardingProfileView)

public enum AppTheme {
  public static let primary: Color = .blue
  public static let controlRadius: CGFloat = 12
  public static let cardRadius: CGFloat = 16
}

// MARK: - AppBackground (Dark Professional - matches OnboardingProfileView exactly)
struct AppBackground: View {
  var body: some View {
    ZStack {
      // Smooth professional gradient (dark navy → slate → light blue)
      LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 16/255, green: 18/255, blue: 30/255), // dark navy (not pure black)
          Color(red: 24/255, green: 28/255, blue: 45/255), // slate blue mid
          Color(red: 36/255, green: 42/255, blue: 65/255)  // soft blue glow bottom
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      // Optional subtle radial spotlight behind content (breaks up the dark top)
      RadialGradient(
        gradient: Gradient(colors: [
          Color.white.opacity(0.06),
          Color.clear
        ]),
        center: .top,
        startRadius: 50,
        endRadius: 350
      )
      .ignoresSafeArea()
    }
  }
}

// MARK: - Card Style (matches OnboardingProfileView exactly)
struct GlassCard: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(18)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Color.white.opacity(0.05))
          .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
          )
      )
      .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
  }
}

// MARK: - Input Style (matches OnboardingProfileView exactly)
struct InputContainer: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Color.white.opacity(0.05))
          .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
          )
      )
      .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
  }
}

// MARK: - Button Style (matches OnboardingProfileView exactly)
struct PrimaryButton: ViewModifier {
  let isDisabled: Bool
  
  func body(content: Content) -> some View {
    content
      .font(.system(size: 18, weight: .semibold))
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(Color.blue)
          .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)
      )
      .foregroundColor(.white)
      .opacity(isDisabled ? 0.5 : 1)
  }
}

// MARK: - View Extensions
extension View {
  func appCardStyle() -> some View { modifier(GlassCard()) }
  func appInputStyle() -> some View { modifier(InputContainer()) }
  func appButtonStyle(disabled: Bool = false) -> some View { modifier(PrimaryButton(isDisabled: disabled)) }
}

// MARK: - Helper modifier for placeholder styling
extension View {
  func placeholder<Content: View>(
    when shouldShow: Bool,
    alignment: Alignment = .leading,
    @ViewBuilder placeholder: () -> Content
  ) -> some View {
    ZStack(alignment: alignment) {
      placeholder().opacity(shouldShow ? 1 : 0)
      self
    }
  }
}

// MARK: - Input Components

struct LabeledEmailField: View {
  var icon: String = "envelope"
  var placeholder: String = "Email"
  @Binding var text: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .foregroundStyle(.white.opacity(0.6))

      TextField("", text: $text)
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .textFieldStyle(.plain)
        .foregroundColor(.white)
        .placeholder(when: text.isEmpty) {
          Text(placeholder)
            .foregroundColor(.white.opacity(0.4))
        }
    }
    .appInputStyle()
  }
}

struct LabeledSecureField: View {
  var icon: String = "key.fill"
  var placeholder: String = "Password"
  @Binding var text: String
  @State private var isSecure = true

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .foregroundStyle(.white.opacity(0.6))

      Group {
        if isSecure {
          SecureField("", text: $text)
            .foregroundColor(.white)
            .placeholder(when: text.isEmpty) {
              Text(placeholder)
                .foregroundColor(.white.opacity(0.4))
            }
        } else {
          TextField("", text: $text)
            .textInputAutocapitalization(.never)
            .foregroundColor(.white)
            .placeholder(when: text.isEmpty) {
              Text(placeholder)
                .foregroundColor(.white.opacity(0.4))
            }
        }
      }
      .textFieldStyle(.plain)
      .autocorrectionDisabled(true)

      Button { isSecure.toggle() } label: {
        Image(systemName: isSecure ? "eye.slash" : "eye")
          .foregroundStyle(.white.opacity(0.6))
      }
      .buttonStyle(.plain)
      .contentShape(Rectangle())
    }
    .appInputStyle()
  }
}
