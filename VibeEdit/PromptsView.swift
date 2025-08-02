import SwiftUI

struct PromptsView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var showingAddPromptSheet = false
    @State private var promptToEdit: Prompt? = nil

    var body: some View {
        VStack {
            Text("Number of prompts: \(appModel.prompts.count)")
            if appModel.prompts.isEmpty {
                Text("No prompts saved yet. Add one using the button below.")
                    .foregroundColor(.gray)
                    .padding()
            }
            List {
                ForEach($appModel.prompts) { $prompt in
                    HStack {
                        Text(prompt.name)
                        Spacer()
                        Button(action: {
                            promptToEdit = prompt
                        }) {
                            Image(systemName: "pencil")
                        }
                        Button(action: {
                            if let index = appModel.prompts.firstIndex(where: { $0.id == prompt.id }) {
                                deletePrompt(at: IndexSet(integer: index))
                            }
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                }
                .onDelete(perform: deletePrompt)
            }
            .frame(minHeight: 100) // Added minHeight
            .onAppear { // Added debug print
                print("Prompts in PromptsView: \(appModel.prompts)")
            }
            Button("Add Prompt") {
                showingAddPromptSheet = true
            }
            .padding()
        }
        .sheet(isPresented: $showingAddPromptSheet) {
            AddPromptView()
                .environmentObject(appModel)
        }
        .sheet(item: $promptToEdit) { prompt in
            EditPromptView(prompt: prompt)
                .environmentObject(appModel)
        }
    }

    private func deletePrompt(at offsets: IndexSet) {
        appModel.prompts.remove(atOffsets: offsets)
    }
}

struct AddPromptView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var text: String = ""

    var body: some View {
        VStack {
            Form {
                TextField("Name", text: $name)
                TextField("Prompt", text: $text)
            }
            .padding()
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    let newPrompt = Prompt(name: name, text: text)
                    appModel.prompts.append(newPrompt)
                    dismiss()
                }
                .disabled(name.isEmpty || text.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 400, idealHeight: 200)
    }
}

struct EditPromptView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var text: String
    let prompt: Prompt

    init(prompt: Prompt) {
        self.prompt = prompt
        _name = State(initialValue: prompt.name)
        _text = State(initialValue: prompt.text)
    }

    var body: some View {
        VStack {
            Form {
                TextField("Name", text: $name)
                TextField("Prompt", text: $text)
            }
            .padding()
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    if let index = appModel.prompts.firstIndex(where: { $0.id == prompt.id }) {
                        appModel.prompts[index].name = name
                        appModel.prompts[index].text = text
                    }
                    dismiss()
                }
                .disabled(name.isEmpty || text.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 400, idealHeight: 200)
    }
}