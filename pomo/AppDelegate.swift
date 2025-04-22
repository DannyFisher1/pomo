import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permission
        requestNotificationAuthorization()
        
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Create settings first
        let settings = TimerSettings()
        // Inject settings into the manager
        let manager = PomodoroManager(timerSettings: settings)

        statusBarController = StatusBarController(manager: manager, settings: settings)
    }
    
    // Function to request authorization
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
            // You could handle the granted == false case here if needed
        }
    }
    
    // Delegate method to handle notifications while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show alert and play sound even if app is active
        completionHandler([.banner, .sound]) // Use .banner for temporary display
    }
}
