import SwiftUI

// Struct to represent different markdown elements
struct MarkdownElement: Identifiable {
    let id = UUID()
    let type: MarkdownElementType
    let content: String
}

// Enum for the different types of markdown elements we support
enum MarkdownElementType {
    case heading1
    case heading2
    case heading3
    case paragraph
    case bulletPoint
    case numberedPoint
    case quote
    case code
    case codeBlock
    case image
    case task
    case divider
    case link
}

struct MarkdownRenderer: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseMarkdown(), id: \.id) { element in
                switch element.type {
                case .heading1:
                    Text(element.content)
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                case .heading2:
                    Text(element.content)
                        .font(.system(size: 20, weight: .bold))
                        .padding(.top, 6)
                        .padding(.bottom, 2)
                case .heading3:
                    Text(element.content)
                        .font(.system(size: 18, weight: .bold))
                        .padding(.top, 4)
                        .padding(.bottom, 1)
                case .paragraph:
                    Text(element.content)
                        .font(.body)
                        .padding(.vertical, 2)
                case .bulletPoint:
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 16))
                        Text(element.content)
                            .font(.body)
                    }
                    .padding(.leading, 4)
                case .numberedPoint:
                    let components = element.content.components(separatedBy: ". ")
                    if components.count >= 2, let number = Int(components[0]) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(number).")
                                .font(.system(size: 16))
                                .frame(width: 24, alignment: .trailing)
                            Text(components[1...].joined(separator: ". "))
                                .font(.body)
                        }
                    } else {
                        Text(element.content)
                            .font(.body)
                    }
                case .quote:
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 4)
                        
                        Text(element.content)
                            .font(.body)
                            .italic()
                            .padding(.leading, 12)
                            .padding(.vertical, 8)
                    }
                    .padding(.vertical, 4)
                case .code:
                    Text(element.content)
                        .font(.system(.body, design: .monospaced))
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                case .image:
                    VStack {
                        // In a real app, you would load the actual image
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        if let caption = extractImageCaption(from: element.content) {
                            Text(caption)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                case .codeBlock:
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(element.content)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                case .task:
                    let isChecked = element.content.hasPrefix("[x] ")
                    let taskText = isChecked ? 
                        element.content.replacingOccurrences(of: "[x] ", with: "") : 
                        element.content.replacingOccurrences(of: "[ ] ", with: "")
                    
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                            .foregroundColor(isChecked ? Color.green : Color.primary)
                        
                        Text(taskText)
                            .strikethrough(isChecked)
                            .foregroundColor(isChecked ? Color.secondary : Color.primary)
                    }
                    .padding(.vertical, 2)
                case .divider:
                    Divider()
                        .padding(.vertical, 8)
                case .link:
                    let linkComponents = parseLinkComponents(from: element.content)
                    Button(action: {
                        // In a real app, you would handle opening the URL
                        if let url = URL(string: linkComponents.url), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text(linkComponents.text)
                            .foregroundColor(Color(red: 0.06, green: 0.54, blue: 0.42))
                            .underline()
                    }
                }
            }
        }
    }
    
    private func parseMarkdown() -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = content.components(separatedBy: "\n")
        
        var codeBlockContent = ""
        var inCodeBlock = false
        
        for (index, line) in lines.enumerated() {
            // Handle code blocks
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End of code block
                    elements.append(MarkdownElement(type: .codeBlock, content: codeBlockContent))
                    codeBlockContent = ""
                    inCodeBlock = false
                } else {
                    // Start of code block
                    inCodeBlock = true
                }
                continue
            }
            
            if inCodeBlock {
                codeBlockContent += line + "\n"
                continue
            }
            
            // Normal line processing
            if line.hasPrefix("# ") {
                elements.append(MarkdownElement(type: .heading1, content: line.dropFirst(2).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("## ") {
                elements.append(MarkdownElement(type: .heading2, content: line.dropFirst(3).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("### ") {
                elements.append(MarkdownElement(type: .heading3, content: line.dropFirst(4).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("- ") {
                elements.append(MarkdownElement(type: .bulletPoint, content: line.dropFirst(2).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("* ") {
                elements.append(MarkdownElement(type: .bulletPoint, content: line.dropFirst(2).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("> ") {
                elements.append(MarkdownElement(type: .quote, content: line.dropFirst(2).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("![") {
                elements.append(MarkdownElement(type: .image, content: line))
            } else if line.hasPrefix("[") && line.contains("](") {
                elements.append(MarkdownElement(type: .link, content: line))
            } else if line.hasPrefix("---") {
                elements.append(MarkdownElement(type: .divider, content: ""))
            } else if line.hasPrefix("- [ ] ") || line.hasPrefix("- [x] ") {
                let prefix = line.hasPrefix("- [x] ") ? "[x] " : "[ ] "
                let content = line.replacingOccurrences(of: "- [x] ", with: "")
                                  .replacingOccurrences(of: "- [ ] ", with: "")
                elements.append(MarkdownElement(type: .task, content: prefix + content))
            } else if line.hasPrefix("`") && line.hasSuffix("`") && line.count > 2 {
                // Inline code
                let codeContent = String(line.dropFirst().dropLast())
                elements.append(MarkdownElement(type: .code, content: codeContent))
            } else {
                // Check for numbered list
                let numberPattern = try? NSRegularExpression(pattern: "^\\d+\\. ")
                let nsLine = line as NSString
                let range = NSRange(location: 0, length: nsLine.length)
                
                if let numberPattern = numberPattern, numberPattern.firstMatch(in: line, range: range) != nil {
                    elements.append(MarkdownElement(type: .numberedPoint, content: line))
                } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: line))
                }
            }
        }
        
        return elements
    }
    
    private func extractImageCaption(from markdown: String) -> String? {
        // Format: ![Caption](url)
        guard markdown.hasPrefix("![") else { return nil }
        
        let startIndex = markdown.index(markdown.startIndex, offsetBy: 2)
        
        guard let closingBracketIndex = markdown.firstIndex(of: "]") else { return nil }
        
        return String(markdown[startIndex..<closingBracketIndex])
    }
    
    private func parseLinkComponents(from markdown: String) -> (text: String, url: String) {
        // Format: [Text](url)
        var text = ""
        var url = ""
        
        if let openBracketIndex = markdown.firstIndex(of: "["),
           let closeBracketIndex = markdown.firstIndex(of: "]"),
           let openParenIndex = markdown.firstIndex(of: "("),
           let closeParenIndex = markdown.firstIndex(of: ")"),
           markdown.distance(from: openBracketIndex, to: closeBracketIndex) > 0,
           markdown.distance(from: openParenIndex, to: closeParenIndex) > 0,
           markdown.distance(from: closeBracketIndex, to: openParenIndex) == 1 {
            
            text = String(markdown[markdown.index(after: openBracketIndex)..<closeBracketIndex])
            url = String(markdown[markdown.index(after: openParenIndex)..<closeParenIndex])
        }
        
        return (text, url)
    }
}

// Helper extension to make creating substrings easier
extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
              let range = self[startIndex...].range(of: string, options: options) {
            result.append(range)
            startIndex = range.upperBound
        }
        return result
    }
}

struct MarkdownRenderer_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            MarkdownRenderer(content: """
            # Heading 1
            ## Heading 2
            ### Heading 3
            
            This is a paragraph of text.
            
            - Bullet point 1
            - Bullet point 2
            
            1. Numbered item 1
            2. Numbered item 2
            
            > This is a quote
            
            `inline code`
            
            ```
            function example() {
                return "This is a code block";
            }
            ```
            
            ![Sample Image](placeholder)
            
            - [ ] Unchecked task
            - [x] Checked task
            
            ---
            
            [Link Text](https://example.com)
            """)
            .padding()
        }
    }
}