import Foundation
import SwiftUI

class PomodoroManager: ObservableObject {
    @Published var timeRemaining: Int
    @Published var currentMode: TimerMode = .pomodoro
    @Published var isRunning = false
    @Published var completedPomodoros = 0
    @Published var autoStartNext = false

    private var timer: Timer?
    private var originalDuration: Int = 0

    init() {
        let mode = TimerMode.pomodoro
        self.currentMode = mode
        self.timeRemaining = mode.duration
        self.originalDuration = mode.duration
    }

    func start(duration: Int) {
        // Only set original duration if we're starting fresh
        if !isRunning && timeRemaining == originalDuration {
            originalDuration = duration
            timeRemaining = duration
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

    func reset(duration: Int) {
        pause()
        originalDuration = duration
        timeRemaining = duration
    }

    func switchMode(to newMode: TimerMode, customDuration: Int? = nil) {
        pause()
        currentMode = newMode
        let duration = customDuration ?? newMode.duration
        originalDuration = duration
        timeRemaining = duration
    }

    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            pause()
            if currentMode == .pomodoro {
                completedPomodoros += 1
            }
            if autoStartNext {
                autoCycle()
            }
        }
    }

    private func autoCycle() {
        switch currentMode {
        case .pomodoro:
            switchMode(to: .shortBreak)
            start(duration: currentMode.duration)
        case .shortBreak:
            switchMode(to: .pomodoro)
            start(duration: currentMode.duration)
        case .longBreak:
            switchMode(to: .pomodoro)
            start(duration: currentMode.duration)
        }
    }
}
