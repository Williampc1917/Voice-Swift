//  HTMLText.swift
//  voice-gmail-assistant
//
//  Lightweight SwiftUI wrapper to render HTML content safely.
//

import SwiftUI

struct HTMLText: View {
    let html: String

    var body: some View {
        if let attributedString = html.toAttributedString() {
            // Render with AttributedString
            Text(attributedString)
                .foregroundColor(.white) // keep consistent style
        } else {
            // Fallback if HTML parsing fails
            Text(html)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - HTML to AttributedString Helper
extension String {
    func toAttributedString() -> AttributedString? {
        guard let data = self.data(using: .utf8) else { return nil }
        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]

            let nsAttrStr = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            return AttributedString(nsAttrStr)
        } catch {
            print("❌ Failed to parse HTML: \(error)")
            return nil
        }
    }
}
