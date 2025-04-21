import AppKit
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var manager: PomodoroManager
    private var settings: TimerSettings
    private var updateTimer: Timer?

    init(manager: PomodoroManager, settings: TimerSettings) {
        self.manager = manager
        self.settings = settings

        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 600)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(manager)
                .environmentObject(settings)
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🍅"
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        startStatusTimer()

    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    private func startStatusTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let button = self.statusItem.button else { return }
            let m = self.manager.timeRemaining / 60
            let s = self.manager.timeRemaining % 60
            let formatted = String(format: "%02d:%02d", m, s)
            button.title = "🍅 \(formatted)"
        }
    }
}
