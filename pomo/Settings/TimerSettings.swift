// ───────────────────────────────────────────────────────────────────────────────
// File: pomo/Settings/TimerSettings.swift
// ───────────────────────────────────────────────────────────────────────────────

import Foundation
import SwiftUI

/// Manages your Pomodoro settings with automatic persistence via UserDefaults.
final class TimerSettings: ObservableObject {
    // MARK: – Defaults (Moved up for use in initialization)
    private static func defaultRoutines() -> [Routine] {
        [
            Routine(name: "Standard Pomodoro (4x)", steps: [
                .pomodoro, .shortBreak, .pomodoro, .shortBreak,
                .pomodoro, .shortBreak, .pomodoro, .longBreak
            ]),
            Routine(name: "Pomodoro -> Short Break", steps: [.pomodoro, .shortBreak]),
            Routine(name: "Pomodoro Only", steps: [.pomodoro])
        ]
    }

    private static func encodedDefaultRoutines() -> Data {
        (try? JSONEncoder().encode(defaultRoutines())) ?? Data()
    }

    // MARK: – Persisted Settings
    @AppStorage("pomodoroDuration")      var pomodoroDuration: TimeInterval = 25 * 60
    @AppStorage("shortBreakDuration")    var shortBreakDuration: TimeInterval = 5 * 60
    @AppStorage("longBreakDuration")     var longBreakDuration: TimeInterval = 15 * 60

    @AppStorage("playSounds")            var playSounds: Bool         = true
    @AppStorage("showNotifications")     var showNotifications: Bool  = true
    @AppStorage("colorTheme")            var colorTheme: ColorTheme   = .system
    @AppStorage("completionSoundName")   var completionSoundName: String = "Default"
    @AppStorage("pomodoroIcon") var pomodoroIcon: String = "🍅"
    @AppStorage("shortBreakIcon") var shortBreakIcon: String = "☕️"
    @AppStorage("longBreakIcon") var longBreakIcon: String = "🧘"

    // MARK: - Custom Notification Settings
    @AppStorage("notificationScale") var notificationScale: Double = 1.0 // Scale factor (e.g., 0.8 to 1.5)
    @AppStorage("notificationDuration") var notificationDuration: Double = 3.5 // Duration in seconds (e.g., 2.0 to 10.0)

    // MARK: - Operating Mode
    enum OperatingMode: String, CaseIterable, Identifiable {
        case single = "Single Cycle"
        case cycle = "Repeat Mode"
        case routine = "Follow Routine"
        var id: String { rawValue }
    }
    @AppStorage("operatingMode") var operatingMode: OperatingMode = .routine
    @AppStorage("cycleMode") var cycleMode: TimerMode = .pomodoro // Mode to repeat in Cycle mode

    // MARK: - Routine Settings
    @AppStorage("savedRoutines") private var savedRoutinesData: Data = encodedDefaultRoutines()
    @AppStorage("selectedRoutineID") var selectedRoutineID: String?

    // MARK: - Initialization
    init() {
        // Ensure selectedRoutineID is valid on init
        let routines = getRoutines() // Decode current/default data
        if !routines.contains(where: { $0.id.uuidString == selectedRoutineID }) {
            selectedRoutineID = routines.first?.id.uuidString
        }
    }

    // MARK: - Routine Accessor Methods
    func getRoutines() -> [Routine] {
        if let decodedRoutines = try? JSONDecoder().decode([Routine].self, from: savedRoutinesData) {
            return decodedRoutines
        } else {
            return TimerSettings.defaultRoutines() // Return static defaults on failure
        }
    }

    func saveRoutines(_ routines: [Routine]) {
        savedRoutinesData = (try? JSONEncoder().encode(routines)) ?? TimerSettings.encodedDefaultRoutines()
        // Ensure selectedRoutineID still points to a valid routine
        if !routines.contains(where: { $0.id.uuidString == selectedRoutineID }) {
            selectedRoutineID = routines.first?.id.uuidString
        }
        objectWillChange.send() // Notify observers
    }

    func getSelectedRoutine() -> Routine? {
        let routines = getRoutines()
        return routines.first { $0.id.uuidString == selectedRoutineID } ?? routines.first
    }

    // MARK: – Available Sounds
    let availableSoundNames = ["Default", "Guitar", "Bongos"]

    // MARK: – Theme Enumeration

    enum ColorTheme: String, CaseIterable, Identifiable {
        case system = "System"
        case light  = "Light"
        case dark   = "Dark"

        var id: String { rawValue }
    }

    // MARK: – Reset
    func resetToDefaults() {
        pomodoroDuration    = 25 * 60
        shortBreakDuration  = 5 * 60
        longBreakDuration   = 15 * 60
        playSounds          = true
        showNotifications   = true
        colorTheme          = .system
        completionSoundName = "Default"
        cycleMode           = .pomodoro
        notificationScale = 1.0
        notificationDuration = 3.5
        pomodoroIcon = "🍅"
        shortBreakIcon = "☕️"
        longBreakIcon = "🧘"
        saveRoutines(TimerSettings.defaultRoutines())
    }
}


