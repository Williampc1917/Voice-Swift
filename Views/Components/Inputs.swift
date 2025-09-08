//
//  Inputs.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/8/25.
//

import SwiftUI

// MARK: - Lightweight Design System (shared by other files)

public enum AppTheme {
  public static let primary: Color = .indigo
  public static let controlRadius: CGFloat = 12
  public static let cardRadius: CGFloat = 18

  public static var background: LinearGradient {
    LinearGradient(
      colors: [Color.indigo.opacity(0.60), Color.indigo.opacity(0.25)],
      startPoint: .topLeading, endPoint: .bottomTrailing
    )
  }
}

struct AppBackground: View {
  var body: some View {
    AppTheme.background.ignoresSafeArea()
  }
}

struct GlassCard: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(18)
      .background(.ultraThinMaterial,
                  in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: AppTheme.cardRadius)
          .strokeBorder(.white.opacity(0.15))
      )
      .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
  }
}

struct InputContainer: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(12)
      .background(.thinMaterial,
                  in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: AppTheme.controlRadius)
          .strokeBorder(.white.opacity(0.12))
      )
  }
}

extension View {
  func appCardStyle() -> some View { modifier(GlassCard()) }
  func appInputStyle() -> some View { modifier(InputContainer()) }
}

// MARK: - Inputs

/// Email text field with icon + consistent traits & styling.
struct LabeledEmailField: View {
  var icon: String = "envelope"
  var placeholder: String = "Email"
  @Binding var text: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .foregroundStyle(.secondary)

      TextField(placeholder, text: $text)
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .textFieldStyle(.plain)
    }
    .appInputStyle()
  }
}

/// Password field with eye toggle + consistent styling.
struct LabeledSecureField: View {
  var icon: String = "key.fill"
  var placeholder: String = "Password"
  @Binding var text: String
  @State private var isSecure = true

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .foregroundStyle(.secondary)

      Group {
        if isSecure {
          SecureField(placeholder, text: $text)
        } else {
          TextField(placeholder, text: $text)
            .textInputAutocapitalization(.never)
        }
      }
      .textFieldStyle(.plain)
      .autocorrectionDisabled(true)

      Button { isSecure.toggle() } label: {
        Image(systemName: isSecure ? "eye.slash" : "eye")
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .contentShape(Rectangle())
    }
    .appInputStyle()
  }
}
