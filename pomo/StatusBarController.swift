import AppKit
import SwiftUI
import Combine

class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var manager: PomodoroManager
    private var settings: TimerSettings
    private var updateTimer: Timer?
    private var settingsCancellable: AnyCancellable?
    private var managerModeCancellable: AnyCancellable?

    init(manager: PomodoroManager, settings: TimerSettings) {
        self.manager = manager
        self.settings = settings

        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(manager)
                .environmentObject(settings)
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIcon()
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        startStatusTimer()
        observeSettingsAndManager()
    }

    private func observeSettingsAndManager() {
        settingsCancellable = settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusIcon()
            }
        
        managerModeCancellable = manager.$currentMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                 self?.updateStatusIcon()
            }
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }

        let timeRemaining = manager.timeRemaining
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
        
        let formattedTime: String
        if hours > 0 {
            formattedTime = String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            formattedTime = String(format: "%02d:%02d", minutes, seconds)
        }

        let currentIcon: String
        switch manager.currentMode {
        case .pomodoro: currentIcon = settings.pomodoroIcon
        case .shortBreak: currentIcon = settings.shortBreakIcon
        case .longBreak: currentIcon = settings.longBreakIcon
        }

        // Build monospaced + system-styled title
        let text = "\(currentIcon) \(formattedTime)"
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor // auto adapts to dark/light mode
        ]

        button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private func startStatusTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatusIcon()
        }
        if let timer = updateTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    deinit {
        updateTimer?.invalidate()
        settingsCancellable?.cancel()
        managerModeCancellable?.cancel()
    }
}
