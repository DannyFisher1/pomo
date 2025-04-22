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
}

// Reusable View for H:M:S Picker
struct TimeDurationPicker: View {
    let label: String
    let icon: String
    @Binding var duration: TimeInterval
    @State private var components: TimeComponents

    // Define reasonable ranges
    private let hourRange = 0...23
    private let minuteSecondRange = 0...59

    init(label: String, icon: String, duration: Binding<TimeInterval>) {
        self.label = label
        self.icon = icon
        self._duration = duration
        // Initialize state based on the binding's initial value
        self._components = State(initialValue: TimeComponents(timeInterval: duration.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(label, systemImage: icon)
                Spacer()
                // Pickers for H, M, S
                HStack(spacing: 2) {
                    picker(value: $components.hours, range: hourRange, unit: "h")
                    picker(value: $components.minutes, range: minuteSecondRange, unit: "m")
                    picker(value: $components.seconds, range: minuteSecondRange, unit: "s")
                }
                .frame(maxWidth: 180) // Adjust width as needed
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            Divider().padding(.leading, 40)
        }
        .onChange(of: components.hours) { _, _ in updateDuration() }
        .onChange(of: components.minutes) { _, _ in updateDuration() }
        .onChange(of: components.seconds) { _, _ in updateDuration() }
        // Ensure the pickers update if the binding changes externally
        .onChange(of: duration) { _, newValue in
            let newComponents = TimeComponents(timeInterval: newValue)
            // Use Equatable conformance for simpler check
            if newComponents != components { // Avoid update loops
                components = newComponents
            }
        }
    }

    // Helper for individual picker views
    @ViewBuilder
    private func picker(value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        HStack(spacing: 1) {
            Picker("", selection: value) {
                ForEach(range, id: \.self) { num in
                    Text("\(num)").tag(num)
                }
            }
            .labelsHidden()
            .frame(minWidth: 35) // Give pickers some minimum width
            .clipped() // Prevents text overlap on narrow widths
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // Update the TimeInterval binding when components change
    private func updateDuration() {
        // Ensure components don't represent the same time interval already set
        // to prevent potential infinite loops if the binding update triggers onChange
        let newInterval = components.timeInterval
        if abs(duration - newInterval) > 0.001 { // Use tolerance for floating point comparison
             duration = newInterval
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var settings: TimerSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showingRoutineManager = false
    @State private var contentSize: CGSize = .zero
    
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
            // Timer Durations - Updated to use TimeDurationPicker
            section(title: "Timer Durations") {
                TimeDurationPicker(label: "Pomodoro", icon: "timer", duration: $settings.pomodoroDuration)
                TimeDurationPicker(label: "Short Break", icon: "cup.and.saucer", duration: $settings.shortBreakDuration)
                TimeDurationPicker(label: "Long Break", icon: "moon.zzz", duration: $settings.longBreakDuration)
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
                                .foregroundColor(step.color)
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
                dismiss()
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
