
import Foundation

struct Prompt: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var text: String
}
