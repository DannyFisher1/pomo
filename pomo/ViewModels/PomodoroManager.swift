import Foundation
import SwiftUI
import Combine
import AppKit // Import AppKit for NSSound & windows
// import UserNotifications // No longer needed for custom alerts

class PomodoroManager: ObservableObject {
    @Published var timeRemaining: TimeInterval
    @Published var currentMode: TimerMode = .pomodoro
    @Published var isRunning = false
    @Published var completedPomodoros = 0 // Keeps track of total pomodoros completed
    @Published var completedShortBreaks = 0 // Add short break counter
    @Published var completedLongBreaks = 0 // Add long break counter
    @Published var currentStepIndex: Int = 0 // Track position in the routine
    @Published var didPerformFullReset: Bool = false // Signal for animation

    private var timer: Timer?
    var originalDuration: TimeInterval = 0
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
        let initialDuration: TimeInterval
        switch initialMode {
        case .pomodoro:
            initialDuration = timerSettings.pomodoroDuration
        case .shortBreak:
            initialDuration = timerSettings.shortBreakDuration
        case .longBreak:
            initialDuration = timerSettings.longBreakDuration
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

    private func duration(for mode: TimerMode) -> TimeInterval {
        switch mode {
        case .pomodoro:
            return timerSettings.pomodoroDuration
        case .shortBreak:
            return timerSettings.shortBreakDuration
        case .longBreak:
            return timerSettings.longBreakDuration
        }
    }

    func start() {
        // Logic to ensure durations are correct before starting remains similar
        let currentModeDuration = duration(for: currentMode)
        // Ensure originalDuration is set correctly if timer was reset or is starting fresh
        if !isRunning && (abs(timeRemaining - originalDuration) < 0.001 || timeRemaining <= 0) {
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
             // Reset the current single mode timer (this is already correct)
             let currentModeDuration = duration(for: currentMode)
             originalDuration = currentModeDuration
             timeRemaining = currentModeDuration
             // Ensure index is consistent if needed elsewhere, though less relevant here
             currentStepIndex = 0 
        case .cycle:
             // SHORT RESET: Reset timer for the CURRENTLY active mode in the cycle
             print("Short reset in Cycle mode - resetting timer for \(currentMode)")
             let currentModeDuration = duration(for: currentMode)
             originalDuration = currentModeDuration
             timeRemaining = currentModeDuration
             // DO NOT change currentMode or currentStepIndex
        case .routine:
             // SHORT RESET: Reset timer for the CURRENT step in the routine
             print("Short reset in Routine mode - resetting timer for step \(currentStepIndex): \(currentMode)")
             let currentModeDuration = duration(for: currentMode)
             originalDuration = currentModeDuration
             timeRemaining = currentModeDuration
             // DO NOT change currentMode or currentStepIndex
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
        if timeRemaining > 1.0 {
            timeRemaining -= 1
        } else {
            timeRemaining = 0
            pause()
            finishCycle()
        }
    }

    // MARK: - Notification Content
    private let pomodoroDoneMessages = [
        // Original + Enhanced
        "Pomodoro done. Bet you spent 20 minutes picking a playlist and 5 actually typing.",
        "Time's up! Did you achieve enlightenment, or just get really familiar with that ceiling crack?",
        "Focus session complete. Your contribution was... noted. Somewhere. Maybe.",
        "That's one Pomodoro down. Statistically, you're no closer to finishing.",
        "Ding! You survived. Lower your standards any further and you'll be subterranean.",
        "Congrats, you managed to sit relatively still for 25 minutes. Don't strain yourself reaching for that participation trophy.",
        "Pomodoro complete: Procrastination level: Expert. Actual work level: ...Let's not talk about it.",
        "Well, that was likely pointless. But hey, the clock moved.",
        "You're still here? Bold strategy. Let's see if it pays off. (Narrator: It won't.)",
        "25 minutes of questionable productivity achieved. Don't add it to your LinkedIn skills.",
        "Pomodoro done. Your coffee isn't impressed, and frankly, neither am I.",
        "One more Pomodoro closer to the sweet release of... never mind, just take your break.",
        "Tick tock, motherf*cker. You wasted 25 minutes. Again.",
        "You 'worked'? Or did you just vigorously think about the *concept* of working?",
        "Session finished. Go reward yourself with something you didn't earn.",
        "High five! For mediocrity! Now go blink rapidly for 5 minutes.",
        "Pomodoro complete. The void acknowledges your futile attempt at structure.",
        "Session over. You can now resume scrolling mindlessly with slightly more guilt.",
        "Another Pomodoro sacrificed to the gods of 'I'll do it later.'",
        "Your secret's safe with me. Mostly because nobody cares if you actually worked.",
        "Mission accomplished? More like 'Mission: Avoided Doing Anything Substantial'.",
        "Pomodoro done. Even your therapist is tired of hearing about this project.",
        "25 minutes later and the world is still ending, but slower now, thanks to you.",
        "Pomodoro wrapped—your crippling self-doubt remains perfectly preserved.",

        // New Additions
        "Pomodoro pulverized! Did you crush it, or did it crush your soul?",
        "Time's up! Hope you didn't get lost in the *sauce* of procrastination.",
        "Well done? Or just... done? Either way, stop.",
        "You completed a Pomodoro! Your ancestors would be... confused. But proud? Maybe?",
        "25 minutes evaporated. Poof. Like your motivation.",
        "Ding ding ding! We have a winner! The prize? A 5-minute break from this hellscape.",
        "Pomodoro finished. Time to stare blankly at a *different* screen for a bit.",
        "You did it! You magnificent, marginally productive beast!",
        "Task complete? Or just timer complete? Let's be honest.",
        "That Pomodoro felt longer than a Monday morning meeting.",
        "Achievement unlocked: Mild Focus.",
        "You wrestled that Pomodoro to the ground. It barely put up a fight, lazy tomato.",
        "Finished! Now, quick, forget everything you just did before the break ends.",
        "Pomodoro kaput. Was it fruitful? Or just... reddish?",
        "You absolute unit... of time passage observation.",
        "That's another 25 minutes you'll never get back. Use the next 5 wisely (scrolling counts).",
        "Pomodoro complete. Your brain might actually have generated a watt or two.",
        "Nice. You stayed focused longer than a goldfish. Probably.",
        "Your focus was so intense, I bet squirrels were taking notes. Or laughing.",
        "End of the line for that Pomodoro. Choo choo choose your break activity wisely.",
        "Nailed it. Or, you know, tapped it gently with a tiny hammer. Close enough.",
        "Pomodoro conquered! Now go touch grass... or just open a window for 5 minutes.",
        "Sweet relief! That Pomodoro is history. Like your chances of finishing today.",
        "You're on fire! Or maybe that's just the server rack. Either way, break time!",
        "That was 25 minutes of pure... something. Good job?",
        "Consider that Pomodoro *squashed*."
    ]

    private let shortBreakDoneMessages = [
        // Original + Enhanced
        "Break's over. Back to the digital chain gang, you miserable sod.",
        "Hope you enjoyed that pathetic excuse for an escape. The spreadsheet awaits your tears.",
        "Short break finished. It wasn't enough. It never will be. Now work.",
        "Okay, playtime's over. Wipe the Cheeto dust off and pretend you have a purpose again.",
        "That was short. Like your attention span. Get back to it.",
        "Break ended. Your snack is gone, your hope is dwindling. Perfect time to work!",
        "Time to swap that brief flicker of joy for the cold, dead stare of your monitor.",
        "Short break: accomplished. Burnout: still scheduled for 3 PM.",
        "Break over. Your inbox multiplied while you were gone. Have fun!",
        "Hope that 5-minute power-scroll through Instagram solved all your problems. Back to hell.",
        "300 seconds of freedom, flushed away. Welcome back to the suck.",
        "Break time's up. Dreams of quitting? Still just dreams. Work now.",
        "Back to work—your chair barely had time to get cold. Like your soul.",
        "Enjoy the crushing weight of reality settling back in. Fun, right?",
        "Short break done: your ergonomic setup is judging your posture already.",
        "Break's over! Did you even *do* anything, or just stare into the middle distance?",
        "Snack break ended. You are now 80% crumbs and 20% regret.",
        "Short break complete. Your impending doom called—it's getting impatient.",
        "Time to put the 'pro' back in 'procrastinate'... wait, no, the other thing. Work!",
        "Break finished. Your plants judged you for not watering them. Again.",
        "Short break done. You can now resume pretending to understand what's going on.",
        "Break's over. Your spine just sighed audibly. Get used to it.",
        "Back to work: your keyboard awaits its ritualistic pounding.",
        "Short break concluded. Your sanity didn't return, did it? Didn't think so.",

        // New Additions
        "Aaand we're back. Hope you didn't get used to that 'not working' thing.",
        "Break evaporated faster than free donuts in the office kitchen. Back to it.",
        "That was the appetizer break. The main course of misery awaits.",
        "Times up! Put the phone down. Slowly. No sudden movements.",
        "Break's over, buttercup. Less scrolling, more controlling (your urge to scream).",
        "Hope that blink-and-you-miss-it break was worth it. The grindstone awaits.",
        "Fun time cancelled. Return to your designated suffering station.",
        "The break fairy has departed. Only the deadline goblin remains.",
        "Okay, shake it off. Or just let the existential dread settle back in gently.",
        "That break was shorter than a politician's promise. Back to reality.",
        "Did you stretch? Or just deepen the imprint on your couch? Either way, work time.",
        "Return of the Jedi... No, wait, just the return to your desk. Less exciting.",
        "Break complete. Your to-do list sends its regards. And threats.",
        "The brief ceasefire is over. Resume hostilities with your workload.",
        "Hope you savored those 300 seconds of not being here. Welcome back.",
        "And... scene! End break. Begin new scene: 'The Struggle Continues'.",
        "That break was cute. Now back to the serious business of looking busy.",
        "Time to swap the 'ooo' of relaxation for the 'oof' of obligation.",
        "Micro-nap over? Micro-productivity begins!",
        "The pause button is broken. It's play time. Forever.",
        "That break was just a simulation. The real grind is back online.",
        "Your 5 minutes of fame (or just sitting) are up. Back to anonymity.",
        "Hope you solved world peace in that break. No? Then get back to these emails.",
        "Re-engage! Like on Star Trek, but with more spreadsheets and less hope.",
        "The break has left the building. You should probably get back to yours (your task list).",
        "Time to *ketchup* on work after that short *relish*."
    ]

    private let longBreakDoneMessages = [
        // Original + Enhanced
        "Long break finished. Try not to get whiplash returning to this dumpster fire.",
        "Welcome back from... whatever that was. Did you forget how to type? Doesn't matter, do it anyway.",
        "Hope that was restful! Just kidding, I know you spent it worrying about work. The deadlines certainly didn't rest.",
        "Long break complete. Time to gently reintroduce yourself to the concept of effort. Or just cry.",
        "Aaand you're back. Did you achieve nirvana? No? Then get back to your emails, schmuck.",
        "Long break over. Your ambition is still on vacation, but your responsibilities clocked back in.",
        "You returned? Must be a glutton for punishment. Or just really need the money.",
        "Welcome back to the grind—hope you didn't get too comfortable with non-suffering.",
        "Long break: checked. Ability to cope: still pending. Time to fake it.",
        "Hope you didn't *actually* relax. That's not what breaks are for. They're for *anticipating* the return to work.",
        "Back to work—did you miss the gentle hum of impending failure?",
        "Long break ended. The void noticed your absence and is slightly put out.",
        "Well, that felt like 5 minutes. Ready to feel utterly overwhelmed again?",
        "You survived the long break. Impressive. Now survive the rest of your day. Good luck.",
        "Long break complete. Your motivation packed its bags and left while you were gone.",
        "Vacation's over. The real world called, it wants its soul back.",
        "Long break done. Your guilt built a little nest while you were away. Cozy.",
        "Back in action—and by 'action' I mean 'scrolling through emails until your eyes bleed.'",
        "Break's over. Your chair is probably plotting against you. Sit carefully.",
        "Long break: expired. Like that milk in the back of your fridge. Reality check time.",
        "Re-entry initiated. Brace for the crushing G-force of accumulated tasks.",
        "Long break concluded. Your inbox is now sentient and demands tribute.",
        "You were gone just long enough to forget everything. Perfect. Now panic.",
        "Break over. Procrastination called, it wants its prime time slot back.",

        // New Additions
        "Welcome back to the machine. Did you bring snacks?",
        "Long break liquidated. Time to re-solidify into a work-blob.",
        "The oasis was a mirage. Desert of deadlines ahead.",
        "Ease back in? Nah, cannonball into the pool of despair!",
        "Remember work? It vaguely remembers you. Time to reacquaint.",
        "Hope you charged your batteries. You're gonna need 'em. All of 'em.",
        "The dream is over. The slightly-less-nightmarish reality resumes.",
        "Did you come back voluntarily? Weirdo. Let's get this over with.",
        "Your brief parole has ended. Back to the cell... uh, cubicle.",
        "Long break diffused. The concentration of work is now dangerously high.",
        "You look... rested? Ugh. Don't worry, we'll fix that.",
        "Welcome back. Try to remember where you saved that file. Good luck.",
        "The mothership has recalled you. Prepare for docking with your desk.",
        "Okay, deep breath. Annnnd... dive back into the chaos.",
        "Hope you enjoyed the peace and quiet. It's cancelled.",
        "That break was long enough to forget your password, wasn't it?",
        "Back from the land of the living (or at least, the 'not working'). Time to re-animate.",
        "The interlude is over. The symphony of suffering resumes.",
        "Long break complete. Your chair sends its deepest sympathies.",
        "Did you miss this? Don't lie. Get back to it.",
        "The gates of productivity (or lack thereof) have reopened.",
        "Welcome back to the thunderdome! Two tasks enter, one task leaves (eventually).",
        "Hope that break was long enough to *tide* you over. Back to the grind.",
        "You've returned! Like a recurring nightmare, but with pay.",
        "Break's over. Time to make the donuts... or, you know, answer emails.",
        "Resume normal operations. Warning: 'Normal' may involve screaming internally."
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
            if abs(self.timeRemaining) < 0.001 {
                switch finishedMode { // Use the captured mode
                case .pomodoro: self.completedPomodoros += 1
                case .shortBreak: self.completedShortBreaks += 1
                case .longBreak: self.completedLongBreaks += 1
                }
            }

            // Check Operating Mode before deciding whether to auto-start
            guard self.timerSettings.operatingMode != .single else {
                // Reset time to 0 if it wasn't already, just to be safe
                self.timeRemaining = 0
                return // Stop here
            }

            // Proceed if mode is .cycle or .routine and timer finished correctly
            if abs(self.timeRemaining) < 0.001 && !self.isRunning {
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

    // MARK: - Full Cycle Reset
    func resetFullCycle() {
        pause()
        print("Executing full reset logic...")

        // --- Trigger Animation Signal --- 
        didPerformFullReset = true
        // Reset the signal after a short delay (long enough for animation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.didPerformFullReset = false
        }
        // --------------------------------

        // Reset counters (optional, depending on desired behavior)
        // completedPomodoros = 0
        // completedShortBreaks = 0
        // completedLongBreaks = 0

        switch timerSettings.operatingMode {
        case .single:
            // Reset to the beginning of the *currently selected* single mode
            print("Full reset in Single mode - resetting to start of \(currentMode)")
            let modeDuration = duration(for: currentMode)
            originalDuration = modeDuration
            timeRemaining = modeDuration
            currentStepIndex = 0 // Reset index for consistency, though less relevant here
        case .cycle:
            // Reset to the beginning of the *selected cycle mode*
            print("Full reset in Cycle mode - resetting to start of \(timerSettings.cycleMode)")
            currentMode = timerSettings.cycleMode // Ensure we use the designated cycle mode
            let modeDuration = duration(for: currentMode)
            originalDuration = modeDuration
            timeRemaining = modeDuration
            currentStepIndex = 0 // Reset index
        case .routine:
            // Reset to the VERY beginning of the selected routine
            print("Full reset in Routine mode - resetting to step 0")
            currentStepIndex = 0
            let firstMode = currentRoutine?.steps.first ?? .pomodoro
            currentMode = firstMode
            let modeDuration = duration(for: currentMode)
            originalDuration = modeDuration
            timeRemaining = modeDuration
        }
        // Note: We don't automatically start the timer after a full reset.
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
