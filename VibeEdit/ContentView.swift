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
                    .font(.custom("SF Mono", size: 16.0))
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
                    .font(.custom("SF Mono", size: 16.0))
                    .frame(minWidth: 200, idealWidth: 400, maxWidth: .infinity, minHeight: 200, idealHeight: 400, maxHeight: .infinity)
                    .padding(.top, 5)
                    .opacity(isDiffMode ? 0 : 1)
                    .overlay(Group {
                        if isDiffMode {
                            Text(generateDiff(original: appModel.leftText, modified: rightText))
                                .font(.body.monospaced())
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .padding(.all, 8)
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
        let originalLines = original.components(separatedBy: .newlines)
        let modifiedLines = modified.components(separatedBy: .newlines)

        // A simple line-by-line comparison for demonstration
        // A real diff algorithm (e.g., Myers diff) would be more complex
        var originalIndex = 0
        var modifiedIndex = 0

        while originalIndex < originalLines.count || modifiedIndex < modifiedLines.count {
            if originalIndex < originalLines.count && modifiedIndex < modifiedLines.count {
                if originalLines[originalIndex] == modifiedLines[modifiedIndex] {
                    // Unchanged line
                    diff.append(AttributedString("  " + originalLines[originalIndex] + "\n"))
                    originalIndex += 1
                    modifiedIndex += 1
                } else {
                    // Changed line
                    var removedLine = AttributedString("-" + originalLines[originalIndex] + "\n")
                    removedLine.foregroundColor = .red
                    diff.append(removedLine)
                    var addedLine = AttributedString("+" + modifiedLines[modifiedIndex] + "\n")
                    addedLine.foregroundColor = .green
                    diff.append(addedLine)
                    originalIndex += 1
                    modifiedIndex += 1
                }
            } else if originalIndex < originalLines.count {
                // Line removed                var removedLine = AttributedString("-" + originalLines[originalIndex] + "\n")                removedLine.foregroundColor = .red                diff.append(removedLine)
                originalIndex += 1
            } else if modifiedIndex < modifiedLines.count {
                // Line added
                var addedLine = AttributedString("+" + modifiedLines[modifiedIndex] + "\n")
                addedLine.foregroundColor = .green
                diff.append(addedLine)
                modifiedIndex += 1
            }
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