import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var manager: PomodoroManager
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Mode indicator
            modeIndicator
            
            // Timer display
            RingTimerView(
                timeRemaining: $manager.timeRemaining,
                totalTime: manager.currentMode.duration,
                color: manager.currentMode.color
            )
            .padding(.vertical, 20)
            
            // Control buttons
            controlButtons
            
            // Mode picker
            modePicker
            
            // Stats and settings
            statsAndSettings
            
            Spacer()
            Color.clear.frame(height: 20)

        }
        .padding()
        .frame(width: 320, height: 500)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
    }
    
    // MARK: - Subviews
    
    private var modeIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: manager.currentMode.icon)
                .foregroundColor(manager.currentMode.color)
            Text(manager.currentMode.description)
                .font(.headline)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(manager.currentMode.color.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var controlButtons: some View {
        HStack(spacing: 16) {
            Button {
                manager.isRunning ? manager.pause() : manager.start(duration: manager.currentMode.duration)
            } label: {
                Label(manager.isRunning ? "Pause" : "Start",
                      systemImage: manager.isRunning ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PomodoroButtonStyle(backgroundColor: manager.currentMode.color))
            
            Button {
                manager.reset(duration: manager.currentMode.duration)
            } label: {
                Label("Reset", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PomodoroButtonStyle(backgroundColor: .gray))
        }
        .padding(.horizontal)
    }
    
    private var modePicker: some View {
        Picker("Timer Mode", selection: $manager.currentMode) {
            ForEach(TimerMode.allCases) { mode in
                Label {
                    Text(mode.rawValue)
                } icon: {
                    Image(systemName: mode.icon)
                }
                .tag(mode)
                .foregroundColor(mode.color)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: manager.currentMode) { oldMode, newMode in
            manager.switchMode(to: newMode)
        }
    }
    
    private var statsAndSettings: some View {
        VStack(spacing: 12) {
            HStack {
                statItem(icon: "checkmark.circle",
                        value: "\(manager.completedPomodoros)",
                        label: "Sessions")
                
                Divider()
                    .frame(height: 40)
                
                statItem(icon: "arrow.clockwise.circle",
                        value: manager.autoStartNext ? "ON" : "OFF",
                        label: "Auto Cycle")
            }
            
            Button(action: { showSettings.toggle() }) {
                Label("Settings", systemImage: "gearshape")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .frame(width: 400, height: 300)
            }
        }
        .padding()
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.title3, weight: .semibold))
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Button Style

struct PomodoroButtonStyle: ButtonStyle {
    var backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .padding(12)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
