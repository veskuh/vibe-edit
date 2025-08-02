import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Binding var document: TextFile
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var errorManager: ErrorManager
    @State private var rightText: String = ""
    @State private var command: String = ""
    @State private var chatHistory: String = ""
    @State private var isBusy: Bool = false
    @State private var isDiffMode: Bool = false
    @FocusState private var isCommandTextFieldFocused: Bool

    var body: some View {
        VStack {
            HSplitView {
                VStack {
                    Text("Your Draft")
                        .font(.headline)
                        .padding(.top, 5)
                    TextEditor(text: $document.initialText)
                        .font(.custom(appModel.editorFontName, size: CGFloat(appModel.editorFontSize)))
                        .frame(minWidth: 200, idealWidth: 400, maxWidth: .infinity, minHeight: 200, idealHeight: 400, maxHeight: .infinity)
                        .overlay(document.initialText.isEmpty ? Text("Start writing or paste your text here...").foregroundColor(.gray) : nil)
                }
                VStack {
                    Text("AI Suggestion")
                        .font(.headline)
                        .padding(.top, 5)
                    TextEditor(text: $rightText)
                        .font(.custom(appModel.editorFontName, size: CGFloat(appModel.editorFontSize)))
                        .frame(minWidth: 200, idealWidth: 400, maxWidth: .infinity, minHeight: 200, idealHeight: 400, maxHeight: .infinity)
                        .opacity(isDiffMode ? 0 : 1)
                        .overlay(rightText.isEmpty && !isDiffMode ? Text("AI suggestions will appear here after you click Send.").foregroundColor(.gray) : nil)
                        .overlay(Group {
                            if isDiffMode {
                                ScrollView {
                                    Text(generateDiff(original: document.initialText, modified: rightText))
                                        .font(.body.monospaced())
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                        .padding(.all, 8)
                                }
                            }
                        })
                }
            }
            .toolbar {
                ToolbarItem(placement: .status) {
                    if isBusy {
                        ProgressView()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        document.initialText = self.rightText
                        self.rightText = ""
                    }) {
                        Label("Accept AI Text", systemImage: "checkmark.circle")
                    }
                    .disabled(rightText.isEmpty)
                    .labelStyle(.titleAndIcon)
                }
                ToolbarItem(placement: .automatic) {
                    Toggle(isOn: $isDiffMode) {
                        Label("Diff Mode", systemImage: "square.split.2x1")
                    }
                    .labelStyle(.titleAndIcon)
                }
            }
            HStack {
                Menu {
                    ForEach(appModel.prompts) { prompt in
                        Button(prompt.name) {
                            command = prompt.text
                            isCommandTextFieldFocused = true
                        }
                    }
                } label: {
                    Image(systemName: "sparkles")
                }
                .menuStyle(.borderlessButton)
                .frame(width: 20)
                
                Text("Ask AI:")
                TextField("Enter your command here", text: $command)
                    .textFieldStyle(.plain)
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .background(Capsule().fill(Color(nsColor: .textBackgroundColor)))
                    .focused($isCommandTextFieldFocused)
                    .onSubmit {
                        Task {
                            await sendToOllama()
                        }
                    }
                Button(action: {
                    Task {
                        await sendToOllama()
                    }
                }) {
                    Label("Send", systemImage: "paperplane.fill")
                }
                .disabled(command.isEmpty)
            }
            .padding()
        }
        .sheet(isPresented: .constant(errorManager.errorMessage != nil), onDismiss: {
            errorManager.errorMessage = nil
        }) {
            ErrorView(errorMessage: $errorManager.errorMessage)
        }
    }
    func sendToOllama() async {
        isBusy = true
        let currentPrompt = "As AI assistant user, I need help with my text. First I'll tell you my request and then I'll tell you the text. Request is: \(command) And here is the text for you to edit as instructed: \(document.initialText)"
        let fullPrompt = chatHistory + currentPrompt
        self.command = ""
        self.rightText = ""
        

        guard let url = URL(string: "\(appModel.ollamaServerAddress)/api/generate") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": appModel.ollamaModel,
            "prompt": fullPrompt,
            "stream": true,
            "system": "You are an expert AI text editor. You will be given a user's command and a piece of text. Your task is to follow the command and modify the text accordingly. Only output the resulting, modified text. Do not add any commentary, greetings, or explanations unless the user's command specifically asks for them."
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (bytes, _) = try await URLSession.shared.bytes(for: request)
            for try await line in bytes.lines {
                let decoder = JSONDecoder()
                if let data = line.data(using: .utf8),
                   let response = try? decoder.decode(OllamaResponse.self, from: data) {
                    DispatchQueue.main.async {
                        self.rightText += response.response
                    }
                }
            }
            DispatchQueue.main.async {
                self.chatHistory += "\nUser Request: \(currentPrompt)\nAI Response: \(self.rightText)"
            }
        } catch {
            let errorMessage = "Error sending request to Ollama: \(error)"
            print(errorMessage)
            DispatchQueue.main.async {
                errorManager.errorMessage = errorMessage
            }
        }
        isBusy = false
    }
    func generateDiff(original: String, modified: String) -> AttributedString {
        if original.isEmpty && modified.isEmpty {
            return AttributedString()
        }

        var diff = AttributedString()

        func tokenize(_ text: String) -> [String] {
            do {
                // This regex splits the string into words and whitespace/newline sequences
                let regex = try NSRegularExpression(pattern: "\\S+|\\s+")
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, range: range)
                return matches.map {
                    String(text[Range($0.range, in: text)!])
                }
            } catch {
                let errorMessage = "Regex error: \(error)"
                print(errorMessage)
                DispatchQueue.main.async {
                    errorManager.errorMessage = errorMessage
                }
                // Fallback to original behavior in case of error
                return text.components(separatedBy: .whitespacesAndNewlines)
            }
        }

        let originalTokens = tokenize(original)
        let modifiedTokens = tokenize(modified)

        // Simple word-by-word diff using a basic longest common subsequence approach
        var dp = Array(repeating: Array(repeating: 0, count: modifiedTokens.count + 1), count: originalTokens.count + 1)

        if !originalTokens.isEmpty && !modifiedTokens.isEmpty {
            for i in 1...originalTokens.count {
                for j in 1...modifiedTokens.count {
                    if originalTokens[i-1] == modifiedTokens[j-1] {
                        dp[i][j] = dp[i-1][j-1] + 1
                    } else {
                        dp[i][j] = max(dp[i-1][j], dp[i][j-1])
                    }
                }
            }
        }

        var i = originalTokens.count
        var j = modifiedTokens.count

        var diffTokens: [(String, Color?)] = []

        while i > 0 || j > 0 {
            if i > 0 && j > 0 && originalTokens[i-1] == modifiedTokens[j-1] {
                diffTokens.append((originalTokens[i-1], nil)) // Unchanged
                i -= 1
                j -= 1
            } else if j > 0 && (i == 0 || dp[i][j-1] >= dp[i-1][j]) {
                diffTokens.append((modifiedTokens[j-1], .green)) // Added
                j -= 1
            } else if i > 0 && (j == 0 || dp[i][j-1] < dp[i-1][j]) {
                diffTokens.append((originalTokens[i-1], .red)) // Removed
                i -= 1
            } else {
                // This case should not be reached, but as a fallback, we break the loop
                break
            }
        }

        for (token, color) in diffTokens.reversed() {
            var attributedToken = AttributedString(token)
            if let color = color {
                attributedToken.foregroundColor = color
            }
            diff.append(attributedToken)
        }

        return diff
    }
}

struct OllamaResponse: Decodable {
    let response: String
}

#Preview {
    ContentView(document: .constant(TextFile()))
}
