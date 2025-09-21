import SwiftUI

struct CleanEmailText: View {
    let html: String
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(parseHtmlToParagraphs(html: html), id: \.self) { paragraph in
                    if let link = paragraph.link {
                        Link(paragraph.text, destination: link)
                            .font(.callout)
                            .foregroundColor(.blue)
                    } else {
                        Text(paragraph.text)
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct Paragraph: Hashable {
    let text: String
    let link: URL?
}

func parseHtmlToParagraphs(html: String) -> [Paragraph] {
    var results: [Paragraph] = []
    
    // Remove styles, scripts, and excessive tags
    let cleaned = html
        .replacingOccurrences(of: "<style[\\s\\S]*?</style>", with: "", options: .regularExpression)
        .replacingOccurrences(of: "<script[\\s\\S]*?</script>", with: "", options: .regularExpression)
    
    // Extract <a> tags separately
    let regex = try! NSRegularExpression(pattern: "<a[^>]*href=\"([^\"]*)\"[^>]*>(.*?)</a>", options: .caseInsensitive)
    let nsString = cleaned as NSString
    let matches = regex.matches(in: cleaned, range: NSRange(location: 0, length: nsString.length))
    
    var replaced = cleaned
    for match in matches.reversed() {
        if match.numberOfRanges == 3 {
            let url = nsString.substring(with: match.range(at: 1))
            let text = nsString.substring(with: match.range(at: 2))
            results.append(Paragraph(text: decodeHTMLEntities(text), link: URL(string: url)))
            
            // Replace the anchor with placeholder
            replaced = (replaced as NSString).replacingCharacters(in: match.range, with: "")
        }
    }
    
    // Remaining plain text
    let plain = replaced
        .replacingOccurrences(of: "<[^>]+>", with: "\n", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    for line in plain.components(separatedBy: .newlines).filter({ !$0.isEmpty }) {
        results.append(Paragraph(text: decodeHTMLEntities(line), link: nil))
    }
    
    return results
}

func decodeHTMLEntities(_ text: String) -> String {
    let attributed = try? NSAttributedString(
        data: Data(text.utf8),
        options: [.documentType: NSAttributedString.DocumentType.html],
        documentAttributes: nil
    )
    return attributed?.string ?? text
}
