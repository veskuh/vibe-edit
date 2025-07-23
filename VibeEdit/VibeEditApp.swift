
import SwiftUI

@main
struct VibeEditApp: App {
    @StateObject private var appModel = AppModel()
    @StateObject private var errorManager = ErrorManager()

    var body: some Scene {
        WindowGroup("VibeEdit") {
            ContentView()
                .environmentObject(appModel)
                .environmentObject(errorManager)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            
            CommandGroup(before: .newItem) {
                Button("New") {
                    appModel.newDocument()
                }
                .keyboardShortcut("n")
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
                .environmentObject(errorManager)
        }
    }
}
