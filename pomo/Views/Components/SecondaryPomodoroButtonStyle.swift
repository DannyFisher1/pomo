import SwiftUI

struct SecondaryPomodoroButtonStyle: ButtonStyle {
    // No specific color needed, uses system secondary/tertiary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline) // Match font size used in ControlButtonsView
            .foregroundColor(.secondary) // Use secondary text color
            .padding(.horizontal, 12) // Match PomodoroButtonStyle padding
            .padding(.vertical, 8)   // Match PomodoroButtonStyle padding
            .background(.quaternary) // Use a subtle background (adjust as needed)
            .clipShape(RoundedRectangle(cornerRadius: 8)) // Match PomodoroButtonStyle radius
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
} 