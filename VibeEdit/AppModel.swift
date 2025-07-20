
import Foundation
import SwiftUI

public class AppModel: ObservableObject {
    @Published var leftText: String = ""
    @Published var showFileImporter: Bool = false
}
