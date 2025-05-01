import AppKit
import SwiftUI
import Combine

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var manager: PomodoroManager
    private var settings: TimerSettings
    private var updateTimer: Timer?
    private var settingsCancellable: AnyCancellable?
    private var managerModeCancellable: AnyCancellable?
    private var settingsWindowController: NSWindowController?
    private var openSettingsObserver: Any?

    init(manager: PomodoroManager, settings: TimerSettings) {
        // 1. Initialize properties specific to this class
        self.manager = manager
        self.settings = settings
        self.popover = NSPopover()
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Optionals (like updateTimer, cancellables, windowController, observer) are implicitly nil

        // 2. Call super.init() AFTER initializing own properties
        super.init()

        // 3. Now configure properties and call methods that use self
        popover.contentSize = NSSize(width: 360, height: 500)
        popover.behavior = .applicationDefined
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(manager)
                .environmentObject(settings)
        )

        updateStatusIcon() // Okay to call now
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self // Okay to use self now
        }

        startStatusTimer() // Okay to call now
        observeSettingsAndManager() // Okay to call now
        observeNotifications() // Okay to call now
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

    private func observeNotifications() {
        openSettingsObserver = NotificationCenter.default.addObserver(
            forName: ContentView.openSettingsNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.openSettingsWindow()
            }
    }

    @objc func openSettingsWindow() {
        if settingsWindowController == nil {
            // … your existing init code …
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()
                .environmentObject(settings)
                .frame(minWidth: 360, idealWidth: 380, maxWidth: 400, minHeight: 500)))
            window.title               = "Pomo Settings"
            window.styleMask          = [.titled, .closable, .miniaturizable, .resizable]
            window.level              = .statusBar         // above popovers & floating windows
            window.isReleasedWhenClosed = false
            settingsWindowController  = NSWindowController(window: window)
        }

        guard let window = settingsWindowController?.window,
              let screen = NSScreen.main?.visibleFrame
        else {
            return
        }

        let margin: CGFloat = 10
        let w = window.frame.width
        let h = window.frame.height

        // top-right: x = maxX – width – margin, y = maxY – height – margin
        let origin = NSPoint(
          x: screen.minX - w - margin,
          y: screen.maxY - h - margin
        )

        window.setFrameOrigin(origin)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }


    deinit {
        updateTimer?.invalidate()
        settingsCancellable?.cancel()
        managerModeCancellable?.cancel()
        if let observer = openSettingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

extension StatusBarController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) == settingsWindowController?.window {
            settingsWindowController = nil
            print("Settings window closed and controller released.")
        }
    }
}
