//
//  ModePickerView.swift
//  pomo
//
//  Created by Danny Fisher on 4/21/25.
//

import SwiftUI

struct ModePickerView: View {
    @EnvironmentObject var manager: PomodoroManager

    var body: some View {
        Picker("Timer Mode", selection: $manager.currentMode) {
            ForEach(TimerMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: manager.currentMode) { _, newMode in
            manager.switchMode(to: newMode)
        }
    }
}
