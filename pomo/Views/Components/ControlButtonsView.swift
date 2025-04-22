//
//  ControlButtonsView.swift
//  pomo
//
//  Created by Danny Fisher on 4/21/25.
//
import SwiftUI

struct ControlButtonsView: View {
    @EnvironmentObject var manager: PomodoroManager

    var body: some View {
        HStack(spacing: 16) {
            // Start/Pause Button
            Button {
                manager.isRunning ? manager.pause() : manager.start()
            } label: {
                Label(manager.isRunning ? "Pause" : "Start",
                      systemImage: manager.isRunning ? "pause.fill" : "play.fill")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PomodoroButtonStyle(backgroundColor: manager.currentMode.color))
            .frame(maxWidth: .infinity, minHeight: 44) // Keep forced height
            
            // Skip/Reset Button
            Button {
                if manager.isRunning {
                    manager.skipCurrentStep()
                } else {
                    manager.reset()
                }
            } label: {
                Label(manager.isRunning ? "Skip" : "Reset",
                      systemImage: manager.isRunning ? "forward.end.fill" : "arrow.clockwise")
                    // Font is now handled by the button style
                    // .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            // Apply the new secondary style
            .buttonStyle(SecondaryPomodoroButtonStyle())
            .frame(maxWidth: .infinity, minHeight: 44) // Keep forced height
        }
        .padding(.horizontal)
    }
}