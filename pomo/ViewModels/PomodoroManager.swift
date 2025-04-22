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
    private var currentRoutine: Routine?
    private var previousOperatingModeSetting: TimerSettings.OperatingMode

    init(timerSettings: TimerSettings) {
        self.timerSettings = timerSettings
        self.previousOperatingModeSetting = timerSettings.operatingMode
        // Load initial routine and set starting state based on Operating Mode
        self.currentRoutine = timerSettings.getSelectedRoutine()
        self.currentStepIndex = 0
        
        let initialMode: TimerMode
        switch timerSettings.operatingMode {
        case .single: initialMode = .pomodoro // Default to pomodoro for single start
        case .cycle: initialMode = timerSettings.cycleMode // Use selected cycle mode
        case .routine: initialMode = currentRoutine?.steps.first ?? .pomodoro // Use first routine step
        }
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

                let opModeChanged = self.previousOperatingModeSetting != self.timerSettings.operatingMode
                let newOperatingMode = self.timerSettings.operatingMode
                let previouslySelectedRoutine = self.currentRoutine
                let newSelectedRoutine = self.timerSettings.getSelectedRoutine()
                let routineChanged = previouslySelectedRoutine != newSelectedRoutine
                let previousCycleMode = self.currentMode // Approximation
                let newCycleMode = self.timerSettings.cycleMode

                // --- Handle Operating Mode Change --- 
                if opModeChanged && !self.isRunning {
                    switch newOperatingMode {
                    case .single:
                        self.switchMode(to: .pomodoro, resetIndex: true)
                    case .cycle:
                        self.switchMode(to: newCycleMode, resetIndex: true)
                    case .routine:
                        self.currentRoutine = newSelectedRoutine
                        self.currentStepIndex = 0
                        let nextMode = self.currentRoutine?.steps.first ?? .pomodoro
                        self.switchMode(to: nextMode, resetIndex: false)
                    }
                // --- Handle Routine Selection Change (within Routine mode) --- 
                } else if newOperatingMode == .routine && routineChanged && !self.isRunning {
                    self.currentRoutine = newSelectedRoutine
                    self.currentStepIndex = 0
                    let nextMode = self.currentRoutine?.steps.first ?? .pomodoro
                    self.switchMode(to: nextMode, resetIndex: false)
                // --- Handle Cycle Mode Selection Change (within Cycle mode) ---
                } else if newOperatingMode == .cycle && previousCycleMode != newCycleMode && !self.isRunning {
                     self.switchMode(to: newCycleMode, resetIndex: true)
                // --- Handle Other Settings Change (like duration) --- 
                } else if !self.isRunning {
                     let newDuration = self.duration(for: self.currentMode)
                     if self.originalDuration != newDuration {
                        self.originalDuration = newDuration
                        self.timeRemaining = newDuration
                    }
                }
                self.previousOperatingModeSetting = newOperatingMode
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
        // Reset to the appropriate starting state based on the *current* operating mode
        switch timerSettings.operatingMode {
        case .single:
             // Reset the current single mode timer
             let currentModeDuration = duration(for: currentMode)
             originalDuration = currentModeDuration
             timeRemaining = currentModeDuration
             // currentStepIndex = 0 // Index is irrelevant here
        case .cycle:
            // Reset to the beginning of the selected cycle mode
            currentMode = timerSettings.cycleMode
            let currentModeDuration = duration(for: currentMode)
            originalDuration = currentModeDuration
            timeRemaining = currentModeDuration
            currentStepIndex = 0 // Reset index for consistency
        case .routine:
            // Reset to the beginning of the current routine
            currentStepIndex = 0
            let mode = currentRoutine?.steps.first ?? .pomodoro
            currentMode = mode
            let currentModeDuration = duration(for: currentMode)
            originalDuration = currentModeDuration
            timeRemaining = currentModeDuration
        }
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

        let finishedMode = self.currentMode // Capture the mode that just finished

        let delayBeforeNextAction: TimeInterval = 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforeNextAction) { [weak self] in
            guard let self = self else { return }

            // Increment total counts based on the captured finished mode
            // Ensure timer is still at 0 before incrementing (in case of rapid manual intervention)
            if self.timeRemaining == 0 {
                switch finishedMode { // Use the captured mode
                case .pomodoro: self.completedPomodoros += 1
                case .shortBreak: self.completedShortBreaks += 1
                case .longBreak: self.completedLongBreaks += 1
                }
            }

            // Check Operating Mode before deciding whether to auto-start
            guard self.timerSettings.operatingMode != .single else {
                return // Stop here
            }

            // Proceed if mode is .cycle or .routine and timer finished correctly
            if self.timeRemaining == 0 && !self.isRunning {
                self.autoCycle()
            }
        }
    }

    // Update autoCycle to handle different operating modes
    private func autoCycle() {
        switch timerSettings.operatingMode {
        case .single:
            break // Should not be reached
        case .cycle:
            // Reset and start the *selected* cycleMode
            currentMode = timerSettings.cycleMode // Ensure currentMode is correct
            let cycleDuration = duration(for: currentMode)
            originalDuration = cycleDuration
            timeRemaining = cycleDuration
            start()
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
        // Increment counter for the mode being skipped
        switch currentMode {
        case .pomodoro: completedPomodoros += 1
        case .shortBreak: completedShortBreaks += 1
        case .longBreak: completedLongBreaks += 1
        }
        
        pause() // Stop the timer

        switch timerSettings.operatingMode {
        case .single:
            timeRemaining = 0
            originalDuration = duration(for: currentMode)
        case .cycle:
            // Reset and start the selected cycle mode
            currentMode = timerSettings.cycleMode // Ensure mode is correct before reset/start
            reset() // Resets time for the (now correct) currentMode
            start() 
        case .routine:
            // Skip in routine mode means advance to the next step.
            guard let routine = currentRoutine, !routine.steps.isEmpty else {
                reset() // Fallback to reset if no routine
                // Should we start after fallback reset? Let's assume yes for now.
                start()
                return
            }
            let nextStepIndex = (currentStepIndex + 1) % routine.steps.count
            let nextMode = routine.steps[nextStepIndex]
            self.currentStepIndex = nextStepIndex
            switchMode(to: nextMode, resetIndex: false) // Switch mode/time
            start() // Immediately start the next step
        }
    }
}
