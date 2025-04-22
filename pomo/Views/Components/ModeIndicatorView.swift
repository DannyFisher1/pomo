//
//  ModeIndicatorView.swift
//  pomo
//
//  Created by Danny Fisher on 4/21/25.
//

import SwiftUI

struct ModeIndicatorView: View {
    // Restore required inputs
    let mode: TimerMode
    let operatingMode: TimerSettings.OperatingMode
    let routine: Routine? // The currently selected routine (if any)
    let currentStepIndex: Int // Current step index within the routine

    // Computed properties for display logic
    private var statusText: String {
        switch operatingMode {
        case .single:
            return "\(mode.rawValue) (Single Cycle)"
        case .cycle:
            return "\(mode.rawValue) (Repeating)"
        case .routine:
            // Just show the current mode name
            return mode.rawValue
        }
    }

    // Bring back nextStepText logic
    private var nextStepText: String? {
        guard operatingMode == .routine, let routine = routine, !routine.steps.isEmpty else {
            return nil // Only show next step for routines
        }
        let nextStepIndex = (currentStepIndex + 1) % routine.steps.count
        let nextStepName = routine.steps[nextStepIndex].rawValue
        return "(Next: \(nextStepName))"
    }

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .foregroundColor(mode.color)
                Text(statusText) // Now simpler for routine mode
                    .font(.headline.weight(.medium))
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(mode.color.opacity(0.1))
            .clipShape(Capsule())

            // Show Next Step below main indicator
            if let nextStep = nextStepText {
                Text(nextStep)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
