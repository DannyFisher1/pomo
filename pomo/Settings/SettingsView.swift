//
//  File: pomo/Settings/SettingsView.swift
//

import SwiftUI
import AppKit // Ensure AppKit is imported for NSSound

extension Notification.Name {
    /// Posted when the user taps "Save" in SettingsView
    static let settingsDidSave = Notification.Name("settingsDidSave")
}

struct SettingsView: View {
    @EnvironmentObject private var settings: TimerSettings
    @Environment(\.dismiss)   private var dismiss
    @State private var showingRoutineManager = false // State for sheet

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
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

            Divider()

            // MARK: Content
            ScrollView {
                VStack(spacing: 20) {
                    section(title: "Timer Durations") {
                        settingRow(icon: "timer",        label: "Pomodoro",     value: $settings.pomodoroMinutes,   range: 1...90)
                        settingRow(icon: "cup.and.saucer", label: "Short Break",  value: $settings.shortBreakMinutes, range: 1...30)
                        settingRow(icon: "moon.zzz",     label: "Long Break",   value: $settings.longBreakMinutes,   range: 1...60)
                    }

                    section(title: "Behavior") {
                        // Add Operating Mode Picker
                        VStack(spacing: 0) {
                            HStack {
                                Label("Timer Mode", systemImage: "repeat.circle")
                                Spacer()
                                Picker("Operating Mode", selection: $settings.operatingMode) {
                                    ForEach(TimerSettings.OperatingMode.allCases) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: 150)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            Divider().padding(.leading, 40)
                        }

                        // Conditionally show Cycle Mode Picker
                        if settings.operatingMode == .cycle {
                            VStack(spacing: 0) {
                                HStack {
                                    Label("Mode to Repeat", systemImage: "repeat")
                                    Spacer()
                                    Picker("Mode to Repeat", selection: $settings.cycleMode) {
                                        ForEach(TimerMode.allCases) { mode in
                                            Text(mode.rawValue).tag(mode)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: 150)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                Divider().padding(.leading, 40)
                            }
                        }

                        toggleRow(icon: "speaker.wave.2",       label: "Play Sounds",     isOn: $settings.playSounds)
                        
                        // Add Sound Picker Row
                        VStack(spacing: 0) {
                            HStack {
                                Label("Completion Sound", systemImage: "music.note")
                                Spacer()
                                Picker("Completion Sound", selection: $settings.completionSoundName) {
                                    ForEach(settings.availableSoundNames, id: \.self) { soundName in
                                        Text(soundName).tag(soundName)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: 150)
                                // Play sound when selection changes
                                .onChange(of: settings.completionSoundName) { _, newSoundName in
                                    NSSound(named: newSoundName)?.play()
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            Divider().padding(.leading, 40)
                        }

                        toggleRow(icon: "bell.badge",           label: "Show Notifications", isOn: $settings.showNotifications)
                    }

                    // Conditionally show Routine section (hide for Single and Cycle)
                    if settings.operatingMode == .routine {
                        section(title: "Active Routine") {
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Select Routine", selection: $settings.selectedRoutineID) {
                                    ForEach(settings.getRoutines()) { routine in
                                        Text(routine.name).tag(routine.id.uuidString as String?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(.bottom, 5)

                                // Display steps of selected routine
                                if let selectedRoutine = settings.getSelectedRoutine() {
                                    Text("Steps in \"\(selectedRoutine.name)\":")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading)

                                    ForEach(Array(selectedRoutine.steps.enumerated()), id: \.offset) { index, step in
                                        HStack {
                                            Text("  \(index + 1).") // Indent step number
                                            Image(systemName: step.icon)
                                                .foregroundColor(step.color)
                                                .frame(width: 20) // Align icons
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

                                // Add Manage Routines Button
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
                                .pickerStyle(.menu)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            Divider().padding(.leading, 40)

                            // Add Mode-Specific Icon TextFields
                            iconSettingRow(label: "Pomodoro Icon", iconBinding: $settings.pomodoroIcon)
                            iconSettingRow(label: "Short Break Icon", iconBinding: $settings.shortBreakIcon)
                            iconSettingRow(label: "Long Break Icon", iconBinding: $settings.longBreakIcon)
                        }
                    }
                    
                    // New Section for Custom Notification Settings
                    section(title: "Custom Notifications") {
                        VStack(spacing: 0) {
                            sliderSettingRow(
                                icon: "arrow.up.left.and.arrow.down.right", 
                                label: "Size Scale", 
                                value: $settings.notificationScale, 
                                range: 0.7...2.0, // Example range
                                step: 0.1, 
                                specifier: "%.1fx"
                            )
                            sliderSettingRow(
                                icon: "hourglass", 
                                label: "Display Duration", 
                                value: $settings.notificationDuration, 
                                range: 2.0...10.0, // Example range
                                step: 0.5, 
                                specifier: "%.1f sec"
                            )
                        }
                    }
                }
                .padding()
            }

            Divider()

            // MARK: Save / Cancel buttons
            HStack {
                Button("Close") {
                    dismiss()
                }
                Spacer()
                Button("Save") {
                    // applyAndSave()
                    // NotificationCenter.default.post(name: .settingsDidSave, object: nil)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 360, minHeight: 550)
        .sheet(isPresented: $showingRoutineManager) { // Add sheet modifier
            RoutineManagementView()
                .environmentObject(settings) // Pass environment object
        }
    }

    // MARK: - Helper for Icon Setting Row
    @ViewBuilder
    private func iconSettingRow(label: String, iconBinding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Use a generic icon for the row label itself
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
        // Add divider unless it's the last item (logic might be needed if more rows added)
        // Divider().padding(.leading, 40)
    }

    // MARK: – Section helper
    @ViewBuilder
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

    // MARK: – Numeric setting row
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

    // MARK: – Toggle setting row
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

    // MARK: - Slider setting row
    private func sliderSettingRow(icon: String, label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, specifier: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Label(label, systemImage: icon)
                Spacer()
                // Format the value display
                Text(String(format: specifier, value.wrappedValue))
                    .frame(width: 70, alignment: .trailing)
            }
            Slider(value: value, in: range, step: step) {
                // Accessibility label
                Text(label)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        // No divider for the last item in the section typically
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(TimerSettings())
    }
}
