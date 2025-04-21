import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let manager = PomodoroManager()
        let settings = TimerSettings()

        statusBarController = StatusBarController(manager: manager, settings: settings)
    }
}
