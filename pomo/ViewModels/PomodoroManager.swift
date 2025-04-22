import Foundation
import SwiftUI
import Combine
import AppKit // Import AppKit for NSSound & windows
// import UserNotifications // No longer needed for custom alerts

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

    // MARK: - Notification Content
    private let pomodoroDoneMessages = [
        "Pomodoro done! Did you actually work, or just stare blankly?",
        "Time's up! Your brain might be slightly less scrambled now.",
        "Focus session complete. Remember what you were doing? Me neither.",
        "That's one Pomodoro down. Only a million more to go.",
        "Ding! You survived another Pomodoro. Reward yourself (briefly).",
        "Congrats, you sat still for 25 minutes. Champagne time.",
        "Pomodoro complete: your procrastination skills remain unparalleled.",
        "Well, that sucked. But hey, it's over.",
        "You're still breathing—success!",
        "25 minutes of faux productivity achieved.",
        "Pomodoro done. Your coffee addiction thanks you.",
        "One more Pomodoro: because misery loves company.",
        "Tick tock, you survived the clock.",
        "You worked? Or did you just think about working?",
        "Session finished. Your snack drawer is calling.",
        "High five! Now go stare at something else for 5 seconds.",
        "Pomodoro complete. The void salutes your effort.",
        "Session over. You can now justify a nap (don't).",
        "Another Pomodoro bites the dust. You monster.",
        "Listen I wont tell them you just sat there for 25 minutes",
        "Mission accomplished: deadlines still looming, though.",
        "Pomodoro done. Your therapist will be proud.",
        "25 minutes later and you still haven't cured boredom.",
        "Pomodoro wrapped—your existential dread remains intact."
    ]

    private let shortBreakDoneMessages = [
        "Break's over! Back to the digital salt mines.",
        "Hope you enjoyed that brief escape. Reality awaits.",
        "Short break finished. Was it enough? Probably not.",
        "Okay, fun time is over. Pretend to be productive again!",
        "That was short, wasn't it? Just like my patience.",
        "Break ended. Your snack is gone, too.",
        "Time to trade dopamine for despair again.",
        "Short break: accomplished. Burnout: incoming.",
        "Break over. Your inbox didn't pray for mercy.",
        "Hope that nap was worth it. Now get back to hell.",
        "30 seconds of joy down the drain.",
        "Break time's up. Dreams of vacation shattered.",
        "Back to work—you masochist.",
        "Enjoy the post-break regret.",
        "Short break done: your chair misses you already.",
        "Break's over! That stretch won't hold itself.",
        "Snack break ended. Crumbs now your new habitat.",
        "Short break complete. Your guilt called—it wants more.",
        "Time to put the 'ugh' back in 'lunch'—just kidding, it wasn't lunch.",
        "Break finished. Your plants still won't water themselves.",
        "Short break done. You can now stare blankly again.",
        "Break's over. Your spine regrets this already.",
        "Back to work: your keyboard misses the crumbs.",
        "Short break concluded. Your sanity? Debatable."
    ]

    private let longBreakDoneMessages = [
        "Long break finished. Ease back in—don't shock the system.",
        "Welcome back from your mini-vacation. Did you miss me?",
        "Hope that was restful! Now, about that looming deadline…",
        "Long break complete. Time to slowly ramp up… or just panic.",
        "Aaand you're back in the room. Let's do this (or procrastinate).",
        "Long break over. Your ambitions are still on holiday.",
        "You came back? Impressive lack of self-respect.",
        "Welcome back to the grind—your therapist called.",
        "Long break: checked. Existential dread: loading.",
        "Hope you didn't actually relax. Now suffer productively.",
        "Back to work—you glorious glutton for punishment.",
        "Long break ended. The void stares back at you.",
        "Well, that was a waste of time. Ready for more?",
        "You survived that long break. Congratulations, I guess.",
        "Long break complete. Your motivation is MIA.",
        "Holiday's over. The real world's resume is pending.",
        "Long break done. Your guilt never left.",
        "Back in action—by 'action' I mean 'endless emails.'",
        "Break's over. Your chair's wheels are mocking you.",
        "Long break: expired. Reality: restocked.",
        "Re-entry successful. Now feel the crushing weight of tasks.",
        "Long break concluded. Your inbox threw a party.",
        "You rested for too long. Now panic accordingly.",
        "Break over. Procrastination's back on stage."
    ]

    private func showCustomAlert(mode: TimerMode) {
        let title: String
        let message: String

        switch mode {
        case .pomodoro:
            title = "Pomodoro Finished!"
            message = pomodoroDoneMessages.randomElement() ?? "Time for a break!"
        case .shortBreak:
            title = "Short Break Over!"
            message = shortBreakDoneMessages.randomElement() ?? "Back to work!"
        case .longBreak:
            title = "Long Break Finished!"
            message = longBreakDoneMessages.randomElement() ?? "Time to focus again!"
        }
        
        // Get the application icon
        let appIcon = NSApplication.shared.applicationIconImage ?? NSImage() // Use default if nil
        
        // Get scale and duration from settings
        let scale = timerSettings.notificationScale
        let duration = timerSettings.notificationDuration
        
        // Create and show the custom window controller with the app icon, scale, and duration
        let alertController = CustomAlertWindowController(
            title: title, 
            message: message, 
            appIcon: appIcon, 
            scale: scale,
            duration: duration
        )
        alertController.show() // Show positions and starts timer
    }

    private func finishCycle() {
        // Play sound first
        if timerSettings.playSounds {
            let soundName = timerSettings.completionSoundName
            NSSound(named: soundName)?.play()
            // Play sound again shortly after (optional, depends on sound length/preference)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSSound(named: soundName)?.play()
            }
        }

        let finishedMode = self.currentMode // Capture the mode that just finished

        // Show custom alert regardless of notification settings
        // Ensure this UI work happens on the main thread
        DispatchQueue.main.async {
            self.showCustomAlert(mode: finishedMode)
        }

        let delayBeforeNextAction: TimeInterval = 2.0 // Keep a small delay
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
