//
//  MeEnvelope.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/8/25.
//

import Foundation

struct MeEnvelope: Decodable {
    let profile: WireUserProfile
    // You can add `auth` later if needed
}
