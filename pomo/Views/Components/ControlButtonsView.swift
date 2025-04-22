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
            Button {
                manager.isRunning ? manager.pause() : manager.start()
            } label: {
                Label(manager.isRunning ? "Pause" : "Start",
                      systemImage: manager.isRunning ? "pause.fill" : "play.fill")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity) // ✅ move here
            .buttonStyle(PomodoroButtonStyle(backgroundColor: manager.currentMode.color))

            Button {
                if manager.isRunning {
                    manager.skipCurrentStep()
                } else {
                    manager.reset()
                }
            } label: {
                Label(manager.isRunning ? "Skip" : "Reset",
                      systemImage: manager.isRunning ? "forward.end.fill" : "arrow.clockwise")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity) // ✅ move here
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
        .padding(.horizontal)
    }
}
