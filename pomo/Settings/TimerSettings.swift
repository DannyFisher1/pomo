import Foundation
import SwiftUI

class TimerSettings: ObservableObject {
    @Published var pomodoroMinutes: Int = 25 {
        didSet { saveToUserDefaults() }
    }
    @Published var shortBreakMinutes: Int = 5 {
        didSet { saveToUserDefaults() }
    }
    @Published var longBreakMinutes: Int = 15 {
        didSet { saveToUserDefaults() }
    }
    @Published var autoStartNext: Bool = false {
        didSet { saveToUserDefaults() }
    }
    
    // Add these new properties
    @Published var colorTheme: ColorTheme = .system {
        didSet { saveToUserDefaults() }
    }
    
    @Published var playSounds: Bool = true {
        didSet { saveToUserDefaults() }
    }
    
    @Published var showNotifications: Bool = true {
        didSet { saveToUserDefaults() }
    }
    
    enum ColorTheme: String, CaseIterable, Identifiable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        var id: String { self.rawValue }
    }
    
    init() {
        loadFromUserDefaults()
    }
    
    private func saveToUserDefaults() {
        UserDefaults.standard.set(pomodoroMinutes, forKey: "pomodoroMinutes")
        UserDefaults.standard.set(shortBreakMinutes, forKey: "shortBreakMinutes")
        UserDefaults.standard.set(longBreakMinutes, forKey: "longBreakMinutes")
        UserDefaults.standard.set(autoStartNext, forKey: "autoStartNext")
        UserDefaults.standard.set(colorTheme.rawValue, forKey: "colorTheme")
        UserDefaults.standard.set(playSounds, forKey: "playSounds")
        UserDefaults.standard.set(showNotifications, forKey: "showNotifications")
    }
    
    private func loadFromUserDefaults() {
        pomodoroMinutes = UserDefaults.standard.integer(forKey: "pomodoroMinutes")
        shortBreakMinutes = UserDefaults.standard.integer(forKey: "shortBreakMinutes")
        longBreakMinutes = UserDefaults.standard.integer(forKey: "longBreakMinutes")
        autoStartNext = UserDefaults.standard.bool(forKey: "autoStartNext")
        playSounds = UserDefaults.standard.bool(forKey: "playSounds")
        showNotifications = UserDefaults.standard.bool(forKey: "showNotifications")
        
        if let themeString = UserDefaults.standard.string(forKey: "colorTheme"),
           let theme = ColorTheme(rawValue: themeString) {
            colorTheme = theme
        }
    }
    
    func resetToDefaults() {
        pomodoroMinutes = 25
        shortBreakMinutes = 5
        longBreakMinutes = 15
        autoStartNext = false
        colorTheme = .system
        playSounds = true
        showNotifications = true
    }
}
