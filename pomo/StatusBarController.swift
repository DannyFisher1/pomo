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
        if let button = statusItem.button {
            button.title = settings.statusBarIcon
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        startStatusTimer()
        observeSettings()
    }

    private func observeSettings() {
        settingsCancellable = settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusIcon()
            }
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        let m = manager.timeRemaining / 60
        let s = manager.timeRemaining % 60
        let formatted = String(format: "%02d:%02d", m, s)
        button.title = "\(settings.statusBarIcon) \(formatted)"
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
    }
}
