
import SwiftUI

struct SettingsView: View {
    @AppStorage("ollamaModel") private var ollamaModel: String = "gemma3:12b"
    @AppStorage("ollamaServerAddress") private var ollamaServerAddress: String = "http://localhost:11434"

    var body: some View {
        Form {
            Section(header: Text("Ollama Settings")) {
                TextField("Ollama Model", text: $ollamaModel)
                TextField("Ollama Server Address", text: $ollamaServerAddress)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}

#Preview {
    SettingsView()
}
