import SwiftUI

enum TimerMode: String, CaseIterable, Identifiable, Codable {
    case pomodoro = "Pomodoro"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    var id: String { self.rawValue }
    
    var duration: Int {
        switch self {
        case .pomodoro: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
    
    var icon: String {
        switch self {
        case .pomodoro: return "timer"
        case .shortBreak: return "cup.and.saucer"
        case .longBreak: return "moon.zzz"
        }
    }
    
    var description: String {
        switch self {
        case .pomodoro: return "Focus session"
        case .shortBreak: return "Short break"
        case .longBreak: return "Long break"
        }
    }
}
