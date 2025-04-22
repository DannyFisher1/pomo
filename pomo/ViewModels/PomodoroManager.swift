import Foundation
import SwiftUI
import Combine
import AppKit // Import AppKit for NSSound

class PomodoroManager: ObservableObject {
    @Published var timeRemaining: Int
    @Published var currentMode: TimerMode = .pomodoro
    @Published var isRunning = false
    @Published var completedPomodoros = 0 // Keeps track of total pomodoros completed
    @Published var completedShortBreaks = 0 // Add short break counter
    @Published var completedLongBreaks = 0 // Add long break counter
    @Published var currentStepIndex: Int = 0 // Track position in the routine

    private var timer: Timer?
    var originalDuration: Int = 0
    private let timerSettings: TimerSettings
    private var settingsCancellable: AnyCancellable?
    private var currentRoutine: Routine? // Store the loaded routine

    init(timerSettings: TimerSettings) {
        self.timerSettings = timerSettings
        // Load initial routine and set starting state
        self.currentRoutine = timerSettings.getSelectedRoutine()
        self.currentStepIndex = 0
        let initialMode = currentRoutine?.steps.first ?? .pomodoro
        self.currentMode = initialMode

        // Calculate initial duration DIRECTLY without calling instance method
        let initialDuration: Int
        switch initialMode {
        case .pomodoro:
            initialDuration = timerSettings.pomodoroMinutes * 60
        case .shortBreak:
            initialDuration = timerSettings.shortBreakMinutes * 60
        case .longBreak:
            initialDuration = timerSettings.longBreakMinutes * 60
        }
        // Now assign properties
        self.timeRemaining = initialDuration
        self.originalDuration = initialDuration

        // Subscribe to settings changes
        settingsCancellable = timerSettings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }

                let previouslySelectedRoutine = self.currentRoutine // Store previous state
                let newSelectedRoutine = self.timerSettings.getSelectedRoutine() // Use function
                let routineChanged = previouslySelectedRoutine != newSelectedRoutine

                if routineChanged {
                    self.currentRoutine = newSelectedRoutine
                    if !self.isRunning {
                        self.currentStepIndex = 0
                        let nextMode = self.currentRoutine?.steps.first ?? .pomodoro
                        self.switchMode(to: nextMode, resetIndex: false)
                    }
                } else {
                    // Routine is the same, but other settings (like duration) might have changed
                    let newDuration = self.duration(for: self.currentMode)
                    if !self.isRunning && self.originalDuration != newDuration {
                        self.originalDuration = newDuration
                        self.timeRemaining = newDuration
                    }
                }
            }
    }

    private func duration(for mode: TimerMode) -> Int {
        switch mode {
        case .pomodoro:
            return timerSettings.pomodoroMinutes * 60
        case .shortBreak:
            return timerSettings.shortBreakMinutes * 60
        case .longBreak:
            return timerSettings.longBreakMinutes * 60
        }
    }

    func start() {
        // Logic to ensure durations are correct before starting remains similar
        let currentModeDuration = duration(for: currentMode)
        // Ensure originalDuration is set correctly if timer was reset or is starting fresh
        if !isRunning && (timeRemaining == originalDuration || timeRemaining == 0) {
             originalDuration = currentModeDuration
             timeRemaining = currentModeDuration
        }

        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.tick()
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
    }

    func reset() {
        pause()
        // Reset to the beginning of the current step in the routine
        currentStepIndex = 0 // Reset step index on manual reset
        let mode = currentRoutine?.steps.first ?? .pomodoro // Reset to first step mode
        if currentMode != mode {
             currentMode = mode // Update mode if it changed
        }
        let currentModeDuration = duration(for: currentMode)
        originalDuration = currentModeDuration
        timeRemaining = currentModeDuration
    }

    // Add resetIndex flag (default true for manual switches)
    func switchMode(to newMode: TimerMode, resetIndex: Bool = true) {
        pause()
        currentMode = newMode
        let duration = self.duration(for: newMode)
        originalDuration = duration
        timeRemaining = duration

        if resetIndex {
            // Find the index of this mode in the routine, default to 0 if not found or no routine
            currentStepIndex = currentRoutine?.steps.firstIndex(of: newMode) ?? 0
        }
        // Removed pomodorosInCurrentCycle logic
    }

    private func tick() {
        if timeRemaining > 1 {
            timeRemaining -= 1
        } else if timeRemaining == 1 {
            timeRemaining = 0
            pause()
            finishCycle()
        }
    }

    private func finishCycle() {
        if timerSettings.playSounds {
            let soundName = timerSettings.completionSoundName
            NSSound(named: soundName)?.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSSound(named: soundName)?.play()
            }
        }

        let delayBeforeNextAction: TimeInterval = 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforeNextAction) { [weak self] in
            guard let self = self else { return }

            // Increment total counts based on the mode that just finished
            if self.timeRemaining == 0 { // Ensure timer actually finished
                switch self.currentMode {
                case .pomodoro: self.completedPomodoros += 1
                case .shortBreak: self.completedShortBreaks += 1
                case .longBreak: self.completedLongBreaks += 1
                }
            }

            // Check Operating Mode before deciding whether to auto-start
            guard self.timerSettings.operatingMode != .single else {
                // In Single Cycle mode, we never auto-start.
                return // Stop here
            }

            // Proceed if mode is .cycle or .routine and timer finished correctly
            if self.timeRemaining == 0 && !self.isRunning {
                self.autoCycle()
            }
            // Timer remains paused at 00:00 if mode is single
        }
    }

    // Update autoCycle to handle different operating modes
    private func autoCycle() {
        switch timerSettings.operatingMode {
        case .single:
            // This case should technically not be reached due to guard in finishCycle
            // but included for completeness. Do nothing.
            break
        case .cycle:
            // Repeat the current mode. No need to switch mode or change index.
            start() // Just start the timer again with the same mode/duration.
        case .routine:
            // Follow the routine steps (existing logic)
            guard let routine = currentRoutine, !routine.steps.isEmpty else {
                // No routine or empty routine, reset to default Pomodoro state and stop.
                if currentMode != .pomodoro {
                     switchMode(to: .pomodoro, resetIndex: true)
                }
                return // Don't start automatically
            }

            let nextStepIndex = (currentStepIndex + 1) % routine.steps.count
            let nextMode = routine.steps[nextStepIndex]

            self.currentStepIndex = nextStepIndex
            switchMode(to: nextMode, resetIndex: false)
            start()
        }
    }

    // MARK: - User Actions
    func skipCurrentStep() {
        pause() // Stop the timer

        // Determine next step based on operating mode
        switch timerSettings.operatingMode {
        case .single:
            // Skip in single mode means finish/reset the current one.
            // Reset timer to 0, keep current mode.
            timeRemaining = 0
            originalDuration = duration(for: currentMode) // Ensure original is correct
        case .cycle:
            // Skip in cycle mode means finish current repetition and reset for next.
            // Reset timer to full duration of the current mode.
            reset() // Use existing reset logic which resets time for current mode
        case .routine:
            // Skip in routine mode means advance to the next step.
            guard let routine = currentRoutine, !routine.steps.isEmpty else {
                reset() // Fallback to reset if no routine
                return
            }
            let nextStepIndex = (currentStepIndex + 1) % routine.steps.count
            let nextMode = routine.steps[nextStepIndex]
            self.currentStepIndex = nextStepIndex
            switchMode(to: nextMode, resetIndex: false) // Switch, don't start
        }
    }
}
