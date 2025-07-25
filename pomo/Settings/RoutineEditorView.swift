import SwiftUI

struct RoutineEditorView: View {
    @Binding var routine: Routine
    @Environment(\.dismiss) var dismiss
    @State private var isEditingList: Bool = false

    // Available modes to add
    let availableModes = TimerMode.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(routine.name.isEmpty ? "Add New Routine" : "Edit Routine")
                .font(.title2)

            TextField("Routine Name", text: $routine.name)
                .textFieldStyle(.roundedBorder)

            Text("Steps:").font(.headline)

            List {
                ForEach($routine.steps, id: \.self) { $step in
                    HStack {
                        Image(systemName: step.icon)
                        Text(step.rawValue)
                    }
                }
                .onMove(perform: moveStep)
                .onDelete(perform: deleteStep)
            }
            .listStyle(.bordered)
            .frame(minHeight: 150)

            HStack {
                Text("Add Step:")
                ForEach(availableModes) { mode in
                    Button {
                        routine.steps.append(mode)
                    } label: {
                        Image(systemName: mode.icon)
                    }
                    .help("Add \(mode.rawValue)") // Tooltip
                }
                Spacer()
                Button(isEditingList ? "Done" : "Edit") {
                    isEditingList.toggle()
                }
            }

            Spacer() // Push controls to bottom

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save") { dismiss() } // Dismissal implies save in parent's onDismiss
                    .keyboardShortcut(.defaultAction)
                    .disabled(routine.name.isEmpty || routine.steps.isEmpty)
            }
        }
        .padding()
        .frame(width: 350, height: 450)
    }

    private func moveStep(from source: IndexSet, to destination: Int) {
        routine.steps.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteStep(at offsets: IndexSet) {
        routine.steps.remove(atOffsets: offsets)
    }
}

// Preview provider (optional but helpful)
struct RoutineEditorView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview for editing
        StatefulPreviewWrapper(Routine(id: UUID(), name: "Preview Routine", steps: [.pomodoro, .shortBreak])) { binding in
            RoutineEditorView(routine: binding)
        }
        .previewDisplayName("Editing Existing")

        // Preview for adding new
        StatefulPreviewWrapper(Routine(id: UUID(), name: "", steps: [])) { binding in
            RoutineEditorView(routine: binding)
        }
        .previewDisplayName("Adding New")
    }
}

// Helper for previews with @State/@Binding
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    var body: some View {
        content($value)
    }

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: value)
        self.content = content
    }
} 
