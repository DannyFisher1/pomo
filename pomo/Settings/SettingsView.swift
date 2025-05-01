import SwiftUI
import AppKit

// Helper struct to manage H:M:S components
struct TimeComponents: Equatable { // Conformance needed for onChange checks
    var hours: Int = 0
    var minutes: Int = 0
    var seconds: Int = 0

    init(timeInterval: TimeInterval) {
        guard timeInterval >= 0 else {
            // Handle negative intervals if necessary, defaulting to 0
            self.hours = 0
            self.minutes = 0
            self.seconds = 0
            return
        }
        let totalSeconds = Int(timeInterval)
        hours = totalSeconds / 3600
        minutes = (totalSeconds % 3600) / 60
        seconds = totalSeconds % 60
    }

    var timeInterval: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }
    
    // Helper to format the duration string
    func formattedString() -> String {
        var components: [String] = []
        if hours > 0 {
            components.append("\(hours)h")
        }
        if minutes > 0 || hours > 0 { // Show minutes if hours are shown or if minutes > 0
             components.append("\(minutes)m")
        }
         // Always show seconds if non-zero, or if it's the only unit
        if seconds > 0 || components.isEmpty {
            components.append("\(seconds)s")
        }
        return components.joined(separator: " ").isEmpty ? "0s" : components.joined(separator: " ")
    }
}

// --- New Views for Elegant Duration Editing ---

// 1. Row View to Display Duration and Trigger Sheet
struct TimeDurationDisplayRow: View {
    let label: String
    let icon: String
    @Binding var duration: TimeInterval
    @State private var showingEditSheet = false

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            Text(TimeComponents(timeInterval: duration).formattedString())
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contentShape(Rectangle()) // Make entire row tappable
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            TimeDurationEditSheet(duration: $duration, label: label)
        }
    }
}

// 2. Sheet View for Editing with Pickers
struct TimeDurationEditSheet: View {
    @Binding var duration: TimeInterval
    let label: String // Pass label for context
    @Environment(\.dismiss) private var dismiss

    // Temporary state for pickers
    @State private var tempComponents: TimeComponents

    // Ranges
    private let hourRange = 0...23
    private let minuteSecondRange = 0...59

    init(duration: Binding<TimeInterval>, label: String) {
        self._duration = duration
        self.label = label
        // Initialize temporary state from the binding
        self._tempComponents = State(initialValue: TimeComponents(timeInterval: duration.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Set Duration for \(label)")
                .font(.headline)

            HStack(spacing: 5) {
                picker(value: $tempComponents.hours, range: hourRange, unit: "h")
                picker(value: $tempComponents.minutes, range: minuteSecondRange, unit: "m")
                picker(value: $tempComponents.seconds, range: minuteSecondRange, unit: "s")
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.black.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain) // Less prominent cancel
                
                Spacer()
                
                Button("Set") {
                    duration = tempComponents.timeInterval // Update binding
                    dismiss()
                }
                .buttonStyle(.borderedProminent) // Prominent set button
            }
        }
        .padding()
        .frame(minWidth: 300)
    }

    // Reusable picker helper (similar to before)
    @ViewBuilder
    private func picker(value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        HStack(spacing: 1) {
            Picker("", selection: value) {
                ForEach(range, id: \.self) { num in
                    Text("\(num)").tag(num)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(minWidth: 45) // Give pickers slightly more width in the sheet
            .clipped()
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var settings: TimerSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showingRoutineManager = false
    @State private var contentSize: CGSize = .zero
    
    // State to manage which custom color picker is shown (if any)
    @State private var currentlyPickingColorFor: TimerMode? = nil
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content with dynamic sizing
            ScrollView {
                contentView
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { contentSize = geo.size }
                                .onChange(of: geo.size) {
                                           contentSize = geo.size
                                       }
                        }
                    )

                   
            }
            .frame(maxHeight: calculateMaxHeight())
            
            Divider()
            
            // Footer buttons
            footerButtons
        }
        .frame(minWidth: 360, idealWidth: 380, maxWidth: 400)
        .sheet(isPresented: $showingRoutineManager) {
            RoutineManagementView()
                .environmentObject(settings)
        }
        .sheet(item: $currentlyPickingColorFor) { mode in
            // Present the NEW ModernColorPickerView
            switch mode {
            case .pomodoro:
                ModernColorPickerView(selectedColor: $settings.pomodoroColor)
            case .shortBreak:
                ModernColorPickerView(selectedColor: $settings.shortBreakColor)
            case .longBreak:
                ModernColorPickerView(selectedColor: $settings.longBreakColor)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text("Settings")
                .font(.headline)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private var contentView: some View {
        VStack(spacing: 20) {
            // Timer Durations - Updated to use TimeDurationDisplayRow
            section(title: "Timer Durations") {
                TimeDurationDisplayRow(label: "Pomodoro", icon: "timer", duration: $settings.pomodoroDuration)
                Divider().padding(.leading, 40) // Add divider between rows
                TimeDurationDisplayRow(label: "Short Break", icon: "cup.and.saucer", duration: $settings.shortBreakDuration)
                Divider().padding(.leading, 40)
                TimeDurationDisplayRow(label: "Long Break", icon: "moon.zzz", duration: $settings.longBreakDuration)
            }
            
            // Behavior
            behaviorSection
            
            // Routine (conditionally shown)
            if settings.operatingMode == .routine {
                routineSection
            }
            
            // Appearance
            appearanceSection
            
            // Custom Notifications
            notificationSection

            // Application Actions (Added Section)
            applicationActionsSection
        }
        .padding()
    }
    
    private var behaviorSection: some View {
        section(title: "Behavior") {
            operatingModeRow
            
            if settings.operatingMode == .cycle {
                cycleModeRow
            }
            
            toggleRow(icon: "speaker.wave.2", label: "Play Sounds", isOn: $settings.playSounds)
            
            soundPickerRow
            
            toggleRow(icon: "bell.badge", label: "Show Notifications", isOn: $settings.showNotifications)
        }
    }
    
    private var operatingModeRow: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Timer Mode", systemImage: "repeat.circle")
                Spacer()
                Picker("", selection: $settings.operatingMode) {
                    ForEach(TimerSettings.OperatingMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 150)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            Divider().padding(.leading, 40)
        }
    }
    
    private var cycleModeRow: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Mode to Repeat", systemImage: "repeat")
                Spacer()
                Picker("", selection: $settings.cycleMode) {
                    ForEach(TimerMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 150)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            Divider().padding(.leading, 40)
        }
    }
    
    private var soundPickerRow: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Completion Sound", systemImage: "music.note")
                Spacer()
                Picker("", selection: $settings.completionSoundName) {
                    ForEach(settings.availableSoundNames, id: \.self) { soundName in
                        Text(soundName).tag(soundName)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 150)
                .onChange(of: settings.completionSoundName) { _, newSoundName in
                    NSSound(named: newSoundName)?.play()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            Divider().padding(.leading, 40)
        }
    }
    
    private var routineSection: some View {
        section(title: "Active Routine") {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Select Routine", selection: $settings.selectedRoutineID) {
                    ForEach(settings.getRoutines()) { routine in
                        Text(routine.name).tag(routine.id.uuidString as String?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.bottom, 5)

                if let selectedRoutine = settings.getSelectedRoutine() {
                    Text("Steps in \"\(selectedRoutine.name)\":")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading)

                    ForEach(Array(selectedRoutine.steps.enumerated()), id: \.offset) { index, step in
                        HStack {
                            Text("  \(index + 1).")
                            Image(systemName: step.icon)
                                .foregroundColor(settings.color(for: step))
                                .frame(width: 20)
                            Text(step.rawValue)
                        }
                        .font(.callout)
                        .padding(.leading)
                    }
                } else {
                    Text("No routine selected or available.")
                        .foregroundColor(.secondary)
                        .padding(.leading)
                }

                HStack {
                    Spacer()
                    Button("Manage Routines...") {
                        showingRoutineManager = true
                    }
                    .buttonStyle(.link)
                }
                .padding(.top, 5)
            }
            .padding(.vertical, 5)
        }
    }
    
    private var appearanceSection: some View {
        section(title: "Appearance") {
            VStack(spacing: 0) {
                HStack {
                    Label("Theme", systemImage: "paintpalette")
                    Spacer()
                    Picker("", selection: $settings.colorTheme) {
                        ForEach(TimerSettings.ColorTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .labelsHidden()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                Divider().padding(.leading, 40)

                iconSettingRow(label: "Pomodoro Icon", iconBinding: $settings.pomodoroIcon)
                iconSettingRow(label: "Short Break Icon", iconBinding: $settings.shortBreakIcon)
                iconSettingRow(label: "Long Break Icon", iconBinding: $settings.longBreakIcon)
                
                Divider().padding(.leading, 40) // Separator
                
                // Use ColorSwatchRow instead of colorPickerRow
                ColorSwatchRow(label: "Pomodoro Color", selectedColor: $settings.pomodoroColor) {
                    currentlyPickingColorFor = .pomodoro
                }
                ColorSwatchRow(label: "Short Break Color", selectedColor: $settings.shortBreakColor) {
                    currentlyPickingColorFor = .shortBreak
                }
                ColorSwatchRow(label: "Long Break Color", selectedColor: $settings.longBreakColor) {
                    currentlyPickingColorFor = .longBreak
                }
                
                Divider().padding(.leading, 40) // Separator
                
                // Update toggle for hover setting
                toggleRow(icon: "eye.slash", label: "Hover for Settings Icon", isOn: $settings.showSettingsIconOnHoverOnly)
            }
        }
    }
    
    private var notificationSection: some View {
        section(title: "Custom Notifications") {
            VStack(spacing: 0) {
                sliderSettingRow(
                    icon: "arrow.up.left.and.arrow.down.right",
                    label: "Size Scale",
                    value: $settings.notificationScale,
                    range: 0.7...2.0,
                    step: 0.1,
                    specifier: "%.1fx"
                )
                sliderSettingRow(
                    icon: "hourglass",
                    label: "Display Duration",
                    value: $settings.notificationDuration,
                    range: 2.0...10.0,
                    step: 0.5,
                    specifier: "%.1f sec"
                )
            }
        }
    }

    // Application Actions Section (Added)
    private var applicationActionsSection: some View {
        section(title: "Application Actions") {
            VStack(spacing: 0) {
                actionRow(icon: "arrow.counterclockwise.circle", label: "Reset All Settings", color: .orange) {
                    settings.resetToDefaults()
                    print("Settings reset to defaults via action row")
                }
                Divider().padding(.leading, 40)
                actionRow(icon: "power.circle.fill", label: "Quit Pomo", color: .red) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
    
    private var footerButtons: some View {
        // Simplified Footer: Only Close button, right-aligned
        HStack {
            Spacer() // Pushes the button to the right
            Button("Close") {
                // Find the hosting window and close it
                NSApp.keyWindow?.close()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    private func calculateMaxHeight() -> CGFloat {
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
        return min(contentSize.height + 100, screenHeight * 0.8)
    }
    
    @ViewBuilder
    private func iconSettingRow(label: String, iconBinding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(label, systemImage: "tag")
                Spacer()
                TextField("", text: iconBinding, prompt: Text("Emoji"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
            }
            Text("Press Ctrl+Cmd+Space for emoji picker.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.leading, 35)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
    
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            VStack(spacing: 0) {
                content()
            }
            .background(.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func toggleRow(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            HStack {
                Label(label, systemImage: icon)
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            Divider()
                .padding(.leading, 40)
        }
    }
    
    private func sliderSettingRow(icon: String, label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, specifier: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Label(label, systemImage: icon)
                Spacer()
                Text(String(format: specifier, value.wrappedValue))
                    .frame(width: 70, alignment: .trailing)
            }
            Slider(value: value, in: range, step: step) {
                Text(label)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    // Action Row Helper (Added)
    private func actionRow(icon: String, label: String, color: Color = .accentColor, action: @escaping () -> Void) -> some View {
         Button(action: action) {
             HStack {
                 Label(label, systemImage: icon)
                     .foregroundColor(color) // Apply color to label
                 Spacer()
                 // Optional: Add a chevron or similar indicator if desired
                 // Image(systemName: "chevron.right")
                 //    .foregroundColor(.secondary)
             }
             .contentShape(Rectangle()) // Make the whole HStack tappable
         }
         .buttonStyle(.plain) // Use plain style to avoid default button appearance
         .padding(.vertical, 8)
         .padding(.horizontal, 12)
     }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(TimerSettings())
    }
}
