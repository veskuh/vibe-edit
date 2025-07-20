import SwiftUI

struct ContentView: View {
    @State private var leftText: String = ""
    @State private var rightText: String = ""
    @State private var command: String = ""
    @State private var chatHistory: String = ""

    var body: some View {
        VStack {
            HSplitView {
                TextEditor(text: $leftText)
                    .frame(minWidth: 200, idealWidth: 400, maxWidth: .infinity, minHeight: 200, idealHeight: 400, maxHeight: .infinity)
                TextEditor(text: $rightText)
                    .frame(minWidth: 200, idealWidth: 400, maxWidth: .infinity, minHeight: 200, idealHeight: 400, maxHeight: .infinity)
            }
            HStack {
                Text("Ask AI:")
                TextField("Enter your command here", text: $command)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    Task {
                        await sendToOllama()
                    }
                }) {
                    Text("Send")
                }
                .disabled(command.isEmpty)
            }
            .padding()
        }
    }
    func sendToOllama() async {
        let currentPrompt = "As AI assistant user, I need help with my text. First I'll tell you my request and then I'll tell you the text. Request is: \(command) And here is the text for you to edit as instructed: \(leftText)"
        let fullPrompt = chatHistory + currentPrompt
        self.command = ""
        self.rightText = ""
        

        guard let url = URL(string: "http://localhost:11434/api/generate") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gemma3:12b",
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
    }
}

struct OllamaResponse: Decodable {
    let response: String
}

#Preview {
    ContentView()
}