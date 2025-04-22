import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    // Static reference to the AppDelegate instance
    static private(set) var instance: AppDelegate!
    
    var statusBarController: StatusBarController?
    // Initialize settings immediately as a non-optional property
    private(set) var settings = TimerSettings()
    private var manager: PomodoroManager! 

    override init() {
        super.init()
        // Set the static instance early in the init process
        AppDelegate.instance = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permission
        requestNotificationAuthorization()
        
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Settings is already initialized, just initialize manager and controller
        manager = PomodoroManager(timerSettings: settings) // Initialize manager
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
