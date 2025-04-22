import Foundation
import SwiftUI // Needed for TimerMode if it's defined elsewhere with SwiftUI elements

// Represents a single step (just the mode for now) in a routine.
// Could be expanded later to include custom durations per step.
typealias RoutineStep = TimerMode

// Represents a named sequence of timer modes.
struct Routine: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var steps: [RoutineStep] // Array of TimerMode enums
} 