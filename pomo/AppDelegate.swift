import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create settings first
        let settings = TimerSettings()
        // Inject settings into the manager
        let manager = PomodoroManager(timerSettings: settings)

        statusBarController = StatusBarController(manager: manager, settings: settings)
    }
}
