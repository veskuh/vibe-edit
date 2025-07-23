import SwiftUI

struct ErrorView: View {
    @Binding var errorMessage: String?

    var body: some View {
        VStack {
            Text("Error")
                .font(.headline)
                .padding()

            Text(errorMessage ?? "An unknown error occurred.")
                .padding()

            Button("OK") {
                errorMessage = nil
            }
            .padding()
        }
        .frame(minWidth: 300, minHeight: 200)
    }
}
