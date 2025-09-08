//
//  Config.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//

import Foundation

enum AppConfig {
  static let supabaseURL = URL(string: "https://ctmlbscmexqqaquvkmko.supabase.co")!
  static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0bWxic2NtZXhxcWFxdXZrbWtvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzMTM2NDUsImV4cCI6MjA3MTg4OTY0NX0.Oz9kUE9_uJGCFg3ki_SQNAqQe2wF9t7HxQMRI5u4k9M"
  static let backendBaseURL = URL(string: "http://127.0.0.1:8000")!
}
