//
//  voice_gmail_assistantApp.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//

import SwiftUI

@main
struct VoiceGmailAssistantApp: App {
  @StateObject private var auth = AuthManager()
  var body: some Scene {
    WindowGroup { ContentView().environmentObject(auth) }
  }
}

