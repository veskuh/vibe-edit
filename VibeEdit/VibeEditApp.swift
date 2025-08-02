
import SwiftUI

@main
struct VibeEditApp: App {
    @StateObject private var appModel = AppModel()
    @StateObject private var errorManager = ErrorManager()

    var body: some Scene {
        DocumentGroup(newDocument: TextFile()) { file in
            ContentView(document: file.$document)
                .environmentObject(appModel)
                .environmentObject(errorManager)
        }
        .defaultSize(width: 1000, height: 800)
        
        .commands {
            CommandGroup(after: .saveItem) {
                // No custom save buttons needed, DocumentGroup handles it
            }
        }
        Settings {
            SettingsView()
                .environmentObject(appModel)
                .environmentObject(errorManager)
        }
    }
}
