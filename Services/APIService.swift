//
//  APIService.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/7/25.
//
//

import Foundation

enum APIError: Error, LocalizedError {
  case badStatus(Int, String)
  case decoding(String)

  var errorDescription: String? {
    switch self {
    case let .badStatus(code, body):
      return "Backend error (\(code)): \(body)"
    case let .decoding(msg):
      return "Failed to read server response: \(msg)"
    }
  }
}

final class APIService {

  func getUserProfile(accessToken: String) async throws -> UserProfile {
    var req = URLRequest(url: AppConfig.backendBaseURL.appendingPathComponent("me"))
    req.httpMethod = "GET"
    req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    let (data, resp) = try await URLSession.shared.data(for: req)
    guard let http = resp as? HTTPURLResponse else {
      throw APIError.badStatus(-1, "No HTTP response")
    }
    guard (200...299).contains(http.statusCode) else {
      let body = String(data: data, encoding: .utf8) ?? ""
      throw APIError.badStatus(http.statusCode, body)
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    do {
      let envelope = try decoder.decode(MeEnvelope.self, from: data)
      let w = envelope.profile

      return UserProfile(
        id: w.userId,
        email: w.email,
        displayName: w.displayName,
        plan: w.plan.name
      )
    } catch {
      let body = String(data: data, encoding: .utf8) ?? ""
      throw APIError.decoding(body)
    }
  }
}




