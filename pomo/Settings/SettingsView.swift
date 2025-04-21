import SwiftUI


struct SettingsView: View {
    @EnvironmentObject var settings: TimerSettings
    // Removed: @State private var contentHeight: CGFloat = 0
    @Environment(\.dismiss) var dismiss // Use dismiss for programmatic closing if presented modally

    var body: some View {
        // Removed outer GeometryReader - not needed for this layout
        ScrollView {
            VStack(alignment: .leading, spacing: 0) { // Use alignment .leading for section titles
                // Header with Close Button
                HStack {
                    Spacer()
                    Button {
                        // Try finding the specific window first if not presented modally
                        if let window = NSApplication.shared.windows.first(where: { $0.contentView is NSHostingView<SettingsView> }) {
                             window.close()
                        } else {
                            // Fallback for other presentation methods or if window finding fails
                             NSApp.keyWindow?.close()
                            // If presented modally (e.g., .sheet), use dismiss:
                            // dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                    .padding([.top, .trailing], 10)
                }
                .padding(.bottom, 10) // Add some space below the close button

                // Timer Durations
                section(title: "Timer Durations") {
                    settingRow(icon: "timer", label: "Pomodoro") {
                        Stepper("", value: $settings.pomodoroMinutes, in: 1...90)
                            .labelsHidden() // Hide Stepper's default label
                        Text("\(settings.pomodoroMinutes) min")
                            .frame(width: 60, alignment: .trailing) // Align text right
                    }
                    settingRow(icon: "cup.and.saucer", label: "Short Break") {
                        Stepper("", value: $settings.shortBreakMinutes, in: 1...30)
                            .labelsHidden()
                        Text("\(settings.shortBreakMinutes) min")
                            .frame(width: 60, alignment: .trailing)
                    }
                    settingRow(icon: "moon.zzz", label: "Long Break") {
                        Stepper("", value: $settings.longBreakMinutes, in: 1...60)
                            .labelsHidden()
                        Text("\(settings.longBreakMinutes) min")
                            .frame(width: 60, alignment: .trailing)
                    }
                }

                // Behavior
                section(title: "Behavior") {
                    settingRow(icon: "arrow.forward.circle", label: "Auto-Start Next") { // Adjusted label
                        Toggle("", isOn: $settings.autoStartNext)
                           .labelsHidden() // Hide Toggle's default label
                           .toggleStyle(.switch) // Ensure it looks like a switch
                    }
                    settingRow(icon: "speaker.wave.2", label: "Play Sounds") {
                        Toggle("", isOn: $settings.playSounds)
                           .labelsHidden()
                           .toggleStyle(.switch)
                    }
                    settingRow(icon: "bell.badge", label: "Show Notifications") { // Adjusted label
                        Toggle("", isOn: $settings.showNotifications)
                           .labelsHidden()
                           .toggleStyle(.switch)
                    }
                }

                // Appearance
                section(title: "Appearance") {
                    settingRow(icon: "paintpalette", label: "Theme") {
                        Picker("", selection: $settings.colorTheme) {
                            ForEach(TimerSettings.ColorTheme.allCases) { theme in
                                Text(theme.rawValue.capitalized).tag(theme) // Capitalize name
                            }
                        }
                        .labelsHidden() // Hide Picker's default label
                        .pickerStyle(.menu)
                        .frame(maxWidth: 150, alignment: .trailing) // Give picker enough width, align right
                    }
                }

                // Reset Button
                Button(role: .destructive) { // Use destructive role for reset/delete actions
                    settings.resetToDefaults()
                } label: {
                    Label("Reset All Settings", systemImage: "trash")
                        .frame(maxWidth: .infinity) // Make label fill width
                        .padding(.vertical, 8) // Adjust padding
                }
                .buttonStyle(.borderedProminent) // Keep prominent style for visibility
                // .tint(.red) // tint is often automatic with .destructive role + prominent style
                .padding(.horizontal, 20) // Keep horizontal padding
                .padding(.top, 20) // Space above button
                .padding(.bottom, 20) // Space below button
            }
            // Removed the inner GeometryReader background modifier
        }
        // Removed the complex frame modifier on ScrollView
        // Apply size constraints here, outside the ScrollView
        .frame(width: 360, height: 550) // Suggestion: Use a fixed size or maxHeight
        // Or use maxHeight for more flexibility:
        // .frame(width: 360, maxHeight: 600)
    }

    // MARK: - Reusable Components (Refined)

    @ViewBuilder // Use @ViewBuilder for the section content
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) { // Added spacing between title and box
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            // Apply background and shape to the content VStack
            VStack(spacing: 0, content: content) // Rows stack tightly
                .background(.background.secondary) // Use semantic background color (adapts to light/dark)
                // Alternatively, use Material: .background(Material.regular)
                .clipShape(RoundedRectangle(cornerRadius: 10)) // Clip the background
                .overlay( // Optional: Add a subtle border
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
                .padding(.horizontal, 20) // Padding around the content box
        }
        .padding(.bottom, 20) // Space below the entire section
    }

    // Make the last row in a section not show a divider
    @ViewBuilder
    private func settingRow<Content: View>(icon: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { // Use VStack to hold row content and divider
            HStack {
                Label(label, systemImage: icon)
                    .foregroundColor(.primary)
                Spacer()
                content() // The control (Stepper, Toggle, Picker)
            }
            .padding(.horizontal, 12) // Padding inside the row
            .padding(.vertical, 10)  // Padding inside the row

            // Add Divider below all rows except the last one (logic handled in section usually)
            // For simplicity here, let's add it always and maybe hide the last one if needed
            Divider()
                .padding(.leading, 40) // Indent divider to align with text/controls
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(TimerSettings()) // Provide mock settings
    }
}
