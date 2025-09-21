//
//  LinkifiedText.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/21/25.
//
import SwiftUI

struct LinkifiedText: View {
    let text: String

    var body: some View {
        let parts = parseLinks(from: text)
        return Text(buildAttributed(parts))
            .font(.callout)
            .foregroundColor(.white.opacity(0.8))
    }

    private func parseLinks(from input: String) -> [(String, URL?)] {
        var result: [(String, URL?)] = []
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: input, range: NSRange(input.startIndex..., in: input)) ?? []

        var lastIndex = input.startIndex
        for match in matches {
            if let range = Range(match.range, in: input) {
                if lastIndex < range.lowerBound {
                    result.append((String(input[lastIndex..<range.lowerBound]), nil))
                }
                if let url = match.url {
                    result.append((String(input[range]), url))
                }
                lastIndex = range.upperBound
            }
        }
        if lastIndex < input.endIndex {
            result.append((String(input[lastIndex...]), nil))
        }
        return result
    }

    private func buildAttributed(_ parts: [(String, URL?)]) -> AttributedString {
        var result = AttributedString()
        for (text, url) in parts {
            var attributed = AttributedString(text)
            if let url = url {
                attributed.link = url
                attributed.foregroundColor = .blue
                attributed.underlineStyle = .single
            }
            result += attributed
        }
        return result
    }
}
