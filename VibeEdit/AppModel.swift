
import Foundation
import SwiftUI

public class AppModel: ObservableObject {
    @Published var leftText: String = ""
    @Published var showFileImporter: Bool = false
    @Published var showSavePanel: Bool = false
    @Published var fileURL: URL? = nil
    @Published var contentToSave: String = ""

    @AppStorage("ollamaModel") var ollamaModel: String = "gemma3:12b"
    @AppStorage("ollamaServerAddress") var ollamaServerAddress: String = "http://localhost:11434"

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
}
