//
//  StatsAndSettingsView.swift
//  pomo
//
//  Created by Danny Fisher on 4/21/25.
//

import SwiftUI
import AppKit

struct StatsAndSettingsView: View {
    @EnvironmentObject var manager: PomodoroManager
    @EnvironmentObject var settings: TimerSettings
    @State private var showSettings = false

    var body: some View {
        HStack(spacing: 0) {
            statItem(icon: TimerMode.pomodoro.icon,
                     value: "\(manager.completedPomodoros)",
                     label: TimerMode.pomodoro.rawValue)
                .frame(maxWidth: .infinity)

            statItem(icon: TimerMode.shortBreak.icon,
                     value: "\(manager.completedShortBreaks)",
                     label: TimerMode.shortBreak.rawValue)
                .frame(maxWidth: .infinity)

            statItem(icon: TimerMode.longBreak.icon,
                     value: "\(manager.completedLongBreaks)",
                     label: TimerMode.longBreak.rawValue)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThickMaterial)
        .clipShape(Capsule())
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .imageScale(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: 15)

                Text(value)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
