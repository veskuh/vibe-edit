import Foundation

struct OllamaTagsResponse: Decodable {
    let models: [OllamaModel]
}

struct OllamaModel: Decodable, Identifiable {
    var id: String { name }
    let name: String
}
