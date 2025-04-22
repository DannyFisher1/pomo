import SwiftUI

struct PomoCommands: Commands {
    // Remove the binding as it's no longer needed
    // @Binding var showingRoutineManagement: Bool
    
    var body: some Commands {
        // Remove the CommandGroup for "Manage Routines..."
        /* REMOVED:
        CommandGroup(after: .appSettings) {
            Button("Manage Routines...") {
                showingRoutineManagement = true
            }
            // Assign a common shortcut (Cmd+Shift+,)
            .keyboardShortcut(",", modifiers: [.command, .shift])
            
            Divider()
        }
        */
        
        // Keep the replacement for the Quit menu item
        CommandGroup(replacing: .appTermination) {
            Button("Quit pomo") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
} 