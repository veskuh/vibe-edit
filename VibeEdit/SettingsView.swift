import SwiftUI

struct SettingsView: View {
    @AppStorage("ollamaModel") private var ollamaModel: String = "gemma3:12b"
    @AppStorage("ollamaServerAddress") private var ollamaServerAddress: String = "http://localhost:11434"
    @AppStorage("editorFontName") private var editorFontName: String = "SF Mono"
    @AppStorage("editorFontSize") private var editorFontSize: Double = 16.0
    @State private var ollamaModels: [OllamaModel] = []
    @EnvironmentObject var errorManager: ErrorManager
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        Form {
            Section(header: Text("Ollama Settings").fontWeight(.bold)) {
                HStack {
                    Picker("Ollama Model", selection: $ollamaModel) {
                        ForEach(ollamaModels) { model in
                            Text(model.name).tag(model.name)
                        }
                    }
                    Button(action: {
                        Task {
                            await fetchOllamaModels()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                TextField("Ollama Server Address", text: $ollamaServerAddress)
            }
            Section(header: Text("Editor Appearance").fontWeight(.bold).padding(.top)) {
                Picker("Font", selection: $editorFontName) {
                    ForEach(AppModel.availableFontNames, id: \.self) { font in
                        Text(font).font(.custom(font, size: 14)).tag(font)
                    }
                }
                Stepper(value: $editorFontSize, in: 10...48, step: 1) {
                    Text("Font Size: \(Int(editorFontSize)) pt")
                }
            }
            Section(header: Text("Prompts").fontWeight(.bold).padding(.top)) {
                PromptsView()
                    .environmentObject(appModel)
            }
        }
        .padding()
        .frame(width: 600, height: 400)
        .onAppear {
            Task {
                await fetchOllamaModels()
            }
        }
    }

    private func fetchOllamaModels() async {
        guard let url = URL(string: "\(ollamaServerAddress)/api/tags") else {
            let errorMessage = "Invalid Ollama server address"
            print(errorMessage)
            errorManager.errorMessage = errorMessage
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
            self.ollamaModels = response.models
        } catch {
            let errorMessage = "Error fetching Ollama models: \(error.localizedDescription)"
            print(errorMessage)
            errorManager.errorMessage = errorMessage
        }
    }
}

#Preview {
    SettingsView()
}