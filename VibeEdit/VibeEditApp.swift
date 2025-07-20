
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
                Button("Open...") {
                    appModel.showFileImporter = true
                }
                .keyboardShortcut("o")
            }
        }
    }
}
