import SwiftUI

struct RoutineManagementView: View {
    @EnvironmentObject var settings: TimerSettings
    @Environment(\.dismiss) var dismiss
    
    // State for presenting the editor sheet
    @State private var showingEditorSheet = false
    // Use a non-optional state for the editor, initialized to a default empty routine
    @State private var routineInEditor: Routine = Routine(id: UUID(), name: "", steps: [])
    // Keep track if we are adding a new one vs editing
    @State private var isAddingNewRoutine: Bool = false

    // State for delete confirmation
    @State private var showingDeleteConfirmation = false
    @State private var routineToDelete: Routine? = nil

    var body: some View {
        VStack {
            HStack {
                Text("Manage Routines")
                    .font(.title2)
                Spacer()
                Button { 
                    // Prepare for adding a new routine
                    routineInEditor = Routine(id: UUID(), name: "", steps: []) // Reset to empty
                    isAddingNewRoutine = true
                    showingEditorSheet = true
                } label: { 
                    Label("Add Routine", systemImage: "plus.circle.fill")
                }
                .labelStyle(.iconOnly)
            }
            .padding([.top, .horizontal])
            
            List {
                ForEach(settings.getRoutines()) { routine in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(routine.name).font(.headline)
                            Text(routine.steps.map { $0.rawValue }.joined(separator: " → "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        // Button to edit existing
                        Button {
                            // Prepare for editing an existing routine
                            routineInEditor = routine // Set editor state to a copy
                            isAddingNewRoutine = false
                            showingEditorSheet = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.plain)
                        .help("Edit Routine") // Add tooltip
                        
                        // Button to delete existing
                        Button {
                            routineToDelete = routine // Set routine to delete
                            showingDeleteConfirmation = true // Show confirmation
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red) // Make it stand out
                        .help("Delete Routine") // Add tooltip
                    }
                }
                .onDelete(perform: deleteRoutineByOffset)
            }
            .listStyle(.inset)

            Spacer()
            
            HStack {
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 450, height: 400)
        .sheet(isPresented: $showingEditorSheet, onDismiss: saveChanges) {
            // Pass the binding to the non-optional editor state
            // Also pass whether we are editing an existing routine - REMOVED
            RoutineEditorView(routine: $routineInEditor)
               // .environmentObject(settings) // REMOVED
        }
        // Add the delete confirmation alert
        .alert("Delete Routine", isPresented: $showingDeleteConfirmation, presenting: routineToDelete) { routine in
            Button("Delete", role: .destructive) {
                confirmDelete(routine: routine)
            }
            Button("Cancel", role: .cancel) { }
        } message: { routine in
            Text("Are you sure you want to delete the routine \"\(routine.name)? This action cannot be undone.")
        }
    }
    
    // Keep swipe-to-delete functionality
    private func deleteRoutineByOffset(at offsets: IndexSet) {
        var routines = settings.getRoutines()
        // Get the routine IDs to delete based on offsets
        let idsToDelete = offsets.map { routines[$0].id }
        // Filter out the routines with those IDs
        routines.removeAll { idsToDelete.contains($0.id) }
        settings.saveRoutines(routines)
        
        // Deselect if the active routine was deleted
        if let activeIdString = settings.selectedRoutineID, 
           let activeIdUUID = UUID(uuidString: activeIdString), 
           idsToDelete.contains(activeIdUUID) {
            settings.selectedRoutineID = nil // Correctly assign nil directly
        }
    }
    
    // Function called by the confirmation alert
    private func confirmDelete(routine: Routine) {
        var routines = settings.getRoutines()
        routines.removeAll { $0.id == routine.id }
        settings.saveRoutines(routines)
        
        // Deselect if the active routine was deleted
        if settings.selectedRoutineID == routine.id.uuidString { // Compare String? and String
            settings.selectedRoutineID = nil // Correctly assign nil directly
        }
    }
    
    // Called when the editor sheet dismisses
    private func saveChanges() {
        // Use routineInEditor which is guaranteed non-optional
        let editedRoutine = routineInEditor 
        
        // Skip saving if name or steps are empty
        guard !editedRoutine.name.isEmpty, !editedRoutine.steps.isEmpty else {
             routineInEditor = Routine(id: UUID(), name: "", steps: []) // Reset editor state
             return
        }

        var routines = settings.getRoutines()
        
        if isAddingNewRoutine {
            // Add the new routine
            routines.append(editedRoutine)
        } else {
            // Update existing routine
            if let index = routines.firstIndex(where: { $0.id == editedRoutine.id }) {
                routines[index] = editedRoutine
            } else {
                 // Should not happen if editing, but handle defensively: add if ID not found
                 routines.append(editedRoutine)
            }
        }
        settings.saveRoutines(routines)
        // Reset editor state after saving
        routineInEditor = Routine(id: UUID(), name: "", steps: []) 
    }
}

struct RoutineManagementView_Previews: PreviewProvider {
    static var previews: some View {
        RoutineManagementView()
            .environmentObject(TimerSettings())
    }
} 