
import SwiftUI

@main
struct VibeEditApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                SettingsLink {
                    Text("Settings...")
                }
                .keyboardShortcut(",")
            }
            CommandGroup(after: .newItem) {
                Button("Open...") {
                    appModel.showFileImporter = true
                }
                .keyboardShortcut("o")
            }
            CommandGroup(after: .saveItem) {
                Button("Save") {
                    appModel.saveContent()
                }
                .keyboardShortcut("s")
                .disabled(appModel.fileURL == nil)
                Button("Save As...") {
                    appModel.contentToSave = appModel.leftText
                    appModel.showSavePanel = true
                }
                .keyboardShortcut("s", modifiers: [.shift, .command])
            }
        }
        Settings {
            SettingsView()
        }
    }
}
