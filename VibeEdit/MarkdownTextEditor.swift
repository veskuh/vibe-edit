import SwiftUI

struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String // Re-enable binding

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()

        textView.delegate = context.coordinator // Delegate is re-enabled
        textView.font = .userFixedPitchFont(ofSize: 14)
        textView.isRichText = true // Re-enable rich text
        textView.isEditable = true // Re-enable editing
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        
        textView.string = text
        context.coordinator.applySyntaxHighlighting(for: textView) // Re-enable highlighting
        
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        
        textView.autoresizingMask = [.width, .height]
        
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selectedRange = textView.selectedRange
            textView.string = text
            textView.selectedRange = selectedRange
            context.coordinator.applySyntaxHighlighting(for: textView) // Re-enable highlighting
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor

        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            applySyntaxHighlighting(for: textView) // Re-enable highlighting
        }
        
        func applySyntaxHighlighting(for textView: NSTextView? = nil) {
            let textView = textView ?? (NSApp.keyWindow?.firstResponder as? NSTextView)
            guard let textView = textView, let textStorage = textView.textStorage else { return }

            let fullRange = NSRange(location: 0, length: textStorage.length)
            textStorage.removeAttribute(.foregroundColor, range: fullRange)
            textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange) // Use labelColor for better adaptability

            // Headings
            let headingRegex = try! NSRegularExpression(pattern: "^(#+)(.*)", options: .anchorsMatchLines)
            headingRegex.enumerateMatches(in: textStorage.string, options: [], range: fullRange) { (match, _, _) in
                if let matchRange = match?.range {
                    textStorage.addAttribute(.foregroundColor, value: NSColor.headerTextColor, range: matchRange)
                }
            }
            
            // Bold
            let boldRegex = try! NSRegularExpression(pattern: "\\*\\*(.*?)\\*\\*")
            boldRegex.enumerateMatches(in: textStorage.string, options: [], range: fullRange) { (match, _, _) in
                if let matchRange = match?.range {
                    textStorage.addAttribute(.foregroundColor, value: NSColor.boldTextColor, range: matchRange)
                }
            }
            
            // Italic
            let italicRegex = try! NSRegularExpression(pattern: #"\\*(.*?)\\*"#)
            italicRegex.enumerateMatches(in: textStorage.string, options: [], range: fullRange) { (match, _, _) in
                if let matchRange = match?.range {
                    textStorage.addAttribute(.foregroundColor, value: NSColor.italicTextColor, range: matchRange)
                }
            }
            
            // HTTP/HTTPS Links
            let linkRegex = try! NSRegularExpression(pattern: #"\[.*?\]\(https?://\S+\)"#)
            linkRegex.enumerateMatches(in: textStorage.string, options: [], range: fullRange) { (match, _, _) in
                if let matchRange = match?.range {
                    textStorage.addAttribute(.foregroundColor, value: NSColor.linkColor, range: matchRange)
                }
            }
            
            // Markdown Image Links
            let imageLinkRegex = try! NSRegularExpression(pattern: #"!\[.*?\]\(.*?\)"#)
            imageLinkRegex.enumerateMatches(in: textStorage.string, options: [], range: fullRange) { (match, _, _) in
                if let matchRange = match?.range {
                    textStorage.addAttribute(.foregroundColor, value: NSColor.imageLinkColor, range: matchRange)
                }
            }
            
            // Hugo Front Matter
            let frontMatterRegex = try! NSRegularExpression(pattern: #"^---\n(.*?)\n---"#, options: [.anchorsMatchLines, .dotMatchesLineSeparators])
            frontMatterRegex.enumerateMatches(in: textStorage.string, options: [], range: fullRange) { (match, _, _) in
                if let matchRange = match?.range {
                    textStorage.addAttribute(.foregroundColor, value: NSColor.frontMatterColor, range: matchRange)
                }
            }
        }
    }
}

extension NSColor {
    static let headerTextColor = NSColor.systemBlue
    static let boldTextColor = NSColor.systemOrange
    static let italicTextColor = NSColor.systemGreen
    static let linkColor = NSColor.systemPurple
    static let imageLinkColor = NSColor.systemTeal
    static let frontMatterColor = NSColor.systemGray
}