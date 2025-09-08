//
//  UserProfile.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//
// app model

struct UserProfile: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String?
    let plan: String?
}
