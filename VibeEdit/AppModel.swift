
import Foundation
import SwiftUI

public class AppModel: ObservableObject {
    @Published var leftText: String = ""
    @Published var showFileImporter: Bool = false
    @Published var showSavePanel: Bool = false
    @Published var fileURL: URL? = nil
    @Published var contentToSave: String = ""
    @Published var prompts: [Prompt] = [] { didSet { savePrompts() } }

    @AppStorage("ollamaModel") var ollamaModel: String = "gemma3:12b"
    @AppStorage("ollamaServerAddress") var ollamaServerAddress: String = "http://localhost:11434"
    @AppStorage("editorFontName") var editorFontName: String = "SF Mono" { didSet { objectWillChange.send() } }
    @AppStorage("editorFontSize") var editorFontSize: Double = 16.0 { didSet { objectWillChange.send() } }

    static let availableFontNames: [String] = {
        // Use a common set of monospaced and system fonts
        ["SF Mono", "Menlo", "Monaco", "Courier", "Courier New", "Fira Mono", "JetBrains Mono", "Andale Mono"]
    }()
    
    init() {
        loadPrompts()
    }

    func saveContent() {
        contentToSave = leftText // Set content to save from leftText
        if fileURL != nil {
            do {
                try contentToSave.write(to: fileURL!, atomically: true, encoding: .utf8)
            } catch {
                print("Error saving file: \(error.localizedDescription)")
            }
        } else {
            showSavePanel = true
        }
    }

    func newDocument() {
        leftText = ""
        fileURL = nil
    }
    
    private func savePrompts() {
        if let encoded = try? JSONEncoder().encode(prompts) {
            UserDefaults.standard.set(encoded, forKey: "savedPrompts")
        }
    }

    private func loadPrompts() {
        if let savedPrompts = UserDefaults.standard.data(forKey: "savedPrompts") {
            if let decodedPrompts = try? JSONDecoder().decode([Prompt].self, from: savedPrompts) {
                prompts = decodedPrompts
                return
            }
        }

        prompts = []
    }
}
