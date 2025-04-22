import SwiftUI
import AppKit

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
            // Timer Durations
            section(title: "Timer Durations") {
                settingRow(icon: "timer", label: "Pomodoro", value: $settings.pomodoroMinutes, range: 1...90)
                settingRow(icon: "cup.and.saucer", label: "Short Break", value: $settings.shortBreakMinutes, range: 1...30)
                settingRow(icon: "moon.zzz", label: "Long Break", value: $settings.longBreakMinutes, range: 1...60)
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
    
    private func settingRow(icon: String, label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 0) {
            HStack {
                Label(label, systemImage: icon)
                Spacer()
                Stepper("", value: value, in: range)
                    .labelsHidden()
                Text("\(value.wrappedValue) min")
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            Divider()
                .padding(.leading, 40)
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
