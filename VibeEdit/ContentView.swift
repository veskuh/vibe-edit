import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var rightText: String = ""
    @State private var command: String = ""
    @State private var chatHistory: String = ""
    @State private var isBusy: Bool = false
    @State private var isDiffMode: Bool = false

    var body: some View {
        VStack {
            HSplitView {
                TextEditor(text: $appModel.leftText)
                    .font(.custom(appModel.editorFontName, size: CGFloat(appModel.editorFontSize)))
                    .frame(minWidth: 200, idealWidth: 400, maxWidth: .infinity, minHeight: 200, idealHeight: 400, maxHeight: .infinity)
                    .padding(.top, 5)
                    .fileImporter(
                        isPresented: $appModel.showFileImporter,
                        allowedContentTypes: [.plainText, .text],
                        allowsMultipleSelection: false
                    ) { result in
                        do {
                            let fileUrl = try result.get().first!
                            guard fileUrl.startAccessingSecurityScopedResource() else { return }
                            let fileContent = try String(contentsOf: fileUrl)
                            appModel.leftText = fileContent
                            appModel.fileURL = fileUrl // Store the URL for subsequent saves
                            fileUrl.stopAccessingSecurityScopedResource()
                        } catch {
                            print("Error reading file: \(error.localizedDescription)")
                        }
                    }
                TextEditor(text: $rightText)
                    .font(.custom(appModel.editorFontName, size: CGFloat(appModel.editorFontSize)))
                    .frame(minWidth: 200, idealWidth: 400, maxWidth: .infinity, minHeight: 200, idealHeight: 400, maxHeight: .infinity)
                    .padding(.top, 5)
                    .opacity(isDiffMode ? 0 : 1)
                    .overlay(Group {
                        if isDiffMode {
                            ScrollView {
                                Text(generateDiff(original: appModel.leftText, modified: rightText))
                                    .font(.body.monospaced())
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .padding(.all, 8)
                            }
                        }
                    })
            }
            .toolbar {
                ToolbarItem(placement: .status) {
                    if isBusy {
                        ProgressView()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        appModel.leftText = self.rightText
                    }) {
                        Text("Accept AI Text")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Toggle(isOn: $isDiffMode) {
                        Text("Diff Mode")
                    }
                }
            }
            HStack {
                Text("Ask AI:")
                TextField("Enter your command here", text: $command)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
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
        .fileExporter(
            isPresented: $appModel.showSavePanel,
            document: TextFile(initialText: appModel.contentToSave),
            contentType: .plainText,
            defaultFilename: "Untitled.txt"
        ) { result in
            switch result {
            case .success(let url):
                appModel.fileURL = url
            case .failure(let error):
                print("Error saving file: \(error.localizedDescription)")
            }
        }
    }
    func sendToOllama() async {
        isBusy = true
        let currentPrompt = "As AI assistant user, I need help with my text. First I'll tell you my request and then I'll tell you the text. Request is: \(command) And here is the text for you to edit as instructed: \(appModel.leftText)"
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
            print("Error sending request to Ollama: \(error)")
        }
        isBusy = false
    }
    func generateDiff(original: String, modified: String) -> AttributedString {
        var diff = AttributedString()
        let originalWords = original.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let modifiedWords = modified.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }

        // Simple word-by-word diff using a basic longest common subsequence approach
        var dp = Array(repeating: Array(repeating: 0, count: modifiedWords.count + 1), count: originalWords.count + 1)

        for i in 1...originalWords.count {
            for j in 1...modifiedWords.count {
                if originalWords[i-1] == modifiedWords[j-1] {
                    dp[i][j] = dp[i-1][j-1] + 1
                } else {
                    dp[i][j] = max(dp[i-1][j], dp[i][j-1])
                }
            }
        }

        var i = originalWords.count
        var j = modifiedWords.count

        var diffWords: [(String, Color?)] = []

        while i > 0 || j > 0 {
            if i > 0 && j > 0 && originalWords[i-1] == modifiedWords[j-1] {
                diffWords.append((originalWords[i-1], nil)) // Unchanged
                i -= 1
                j -= 1
            } else if j > 0 && (i == 0 || dp[i][j-1] >= dp[i-1][j]) {
                diffWords.append((modifiedWords[j-1], .green)) // Added
                j -= 1
            } else if i > 0 && (j == 0 || dp[i][j-1] < dp[i-1][j]) {
                diffWords.append((originalWords[i-1], .red)) // Removed
                i -= 1
            }
        }

        for (word, color) in diffWords.reversed() {
            var attributedWord = AttributedString(word + " ")
            if let color = color {
                attributedWord.foregroundColor = color
            }
            diff.append(attributedWord)
        }

        return diff
    }
}

struct OllamaResponse: Decodable {
    let response: String
}

#Preview {
    ContentView()
}