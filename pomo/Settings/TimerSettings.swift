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
    @AppStorage("pomodoroMinutes")       var pomodoroMinutes: Int     = 25
    @AppStorage("shortBreakMinutes")     var shortBreakMinutes: Int   = 5
    @AppStorage("longBreakMinutes")      var longBreakMinutes: Int    = 15

    @AppStorage("playSounds")            var playSounds: Bool         = true
    @AppStorage("showNotifications")     var showNotifications: Bool  = true
    @AppStorage("colorTheme")            var colorTheme: ColorTheme   = .system
    @AppStorage("completionSoundName")   var completionSoundName: String = "Ping"
    @AppStorage("statusBarIcon")        var statusBarIcon: String = "🍅"

    // MARK: - Operating Mode
    enum OperatingMode: String, CaseIterable, Identifiable {
        case single = "Single Cycle"
        case cycle = "Repeat Mode"
        case routine = "Follow Routine"
        var id: String { rawValue }
    }
    @AppStorage("operatingMode") var operatingMode: OperatingMode = .routine

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
    let availableSoundNames = ["Ping", "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero", "Morse", "Pop", "Purr", "Sosumi", "Submarine", "Tink"]

    // MARK: – Theme Enumeration

    enum ColorTheme: String, CaseIterable, Identifiable {
        case system = "System"
        case light  = "Light"
        case dark   = "Dark"

        var id: String { rawValue }
    }

    // MARK: – Reset
    func resetToDefaults() {
        pomodoroMinutes     = 25
        shortBreakMinutes   = 5
        longBreakMinutes    = 15
        playSounds          = true
        showNotifications   = true
        colorTheme          = .system
        completionSoundName = "Ping"
        statusBarIcon       = "🍅"
        operatingMode       = .routine
        // Reset routines using the save function
        saveRoutines(TimerSettings.defaultRoutines())
        // selectedRoutineID is handled within saveRoutines
    }
}
