
import SwiftUI

struct SettingsView: View {
    @AppStorage("ollamaModel") private var ollamaModel: String = "gemma3:12b"
    @AppStorage("ollamaServerAddress") private var ollamaServerAddress: String = "http://localhost:11434"
    @AppStorage("editorFontName") private var editorFontName: String = "SF Mono"
    @AppStorage("editorFontSize") private var editorFontSize: Double = 16.0

    var body: some View {
        Form {
            Section(header: Text("Ollama Settings")) {
                TextField("Ollama Model", text: $ollamaModel)
                TextField("Ollama Server Address", text: $ollamaServerAddress)
            }
            Section(header: Text("Editor Appearance")) {
                Picker("Font", selection: $editorFontName) {
                    ForEach(AppModel.availableFontNames, id: \.self) { font in
                        Text(font).font(.custom(font, size: 14)).tag(font)
                    }
                }
                Stepper(value: $editorFontSize, in: 10...48, step: 1) {
                    Text("Font Size: \(Int(editorFontSize)) pt")
                }
            }
        }
        .padding()
        .frame(width: 600, height: 250)
    }
}

#Preview {
    SettingsView()
}
