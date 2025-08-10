
import SwiftUI
import Foundation // For UUID and Codable
import Combine // For ObservableObject

struct Snippet: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var content: String
}

class SnippetsManager: ObservableObject {
    @Published var snippets: [Snippet] {
        didSet {
            saveSnippets()
        }
    }

    private let userDefaultsKey = "textSnippets"

    init() {
        _snippets = Published(initialValue: []) // Initialize with an empty array first
        self.snippets = loadSnippets() // Then load from UserDefaults
    }

    private func loadSnippets() -> [Snippet] {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedSnippets = try? JSONDecoder().decode([Snippet].self, from: data) {
                return decodedSnippets
            }
        }
        return []
    }

    private func saveSnippets() {
        if let encoded = try? JSONEncoder().encode(snippets) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func addSnippet(name: String, content: String) {
        let newSnippet = Snippet(name: name, content: content)
        snippets.append(newSnippet)
    }

    func updateSnippet(id: UUID, newName: String, newContent: String) {
        if let index = snippets.firstIndex(where: { $0.id == id }) {
            snippets[index].name = newName
            snippets[index].content = newContent
        }
    }

    func deleteSnippet(id: UUID) {
        snippets.removeAll { $0.id == id }
    }
    
    func delete(at offsets: IndexSet) {
        snippets.remove(atOffsets: offsets)
    }
}

@main
struct VibeEditApp: App {
    @StateObject private var appModel = AppModel()
    @StateObject private var errorManager = ErrorManager()
    @StateObject private var snippetsManager = SnippetsManager() // Added

    var body: some Scene {
        DocumentGroup(newDocument: TextFile()) { file in
            ContentView(document: file.$document)
                .environmentObject(appModel)
                .environmentObject(errorManager)
                .environmentObject(snippetsManager) // Added
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
