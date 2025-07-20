import SwiftUI
import UniformTypeIdentifiers

struct TextFile: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var initialText: String

    init(initialText: String = "") {
        self.initialText = initialText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            initialText = String(decoding: data, as: UTF8.self)
        } else {
            initialText = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = initialText.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
