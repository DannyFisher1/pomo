import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var manager: PomodoroManager
    @EnvironmentObject var settings: TimerSettings
    @Environment(\.colorScheme) var systemColorScheme
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 15) {
                VStack(spacing: 15) {
                    ModeIndicatorView(
                        mode: manager.currentMode,
                        operatingMode: settings.operatingMode,
                        routine: settings.getSelectedRoutine(),
                        currentStepIndex: manager.currentStepIndex
                    )

                    ZStack {
                        RingTimerView(
                            timeRemaining: $manager.timeRemaining,
                            totalTime: manager.originalDuration,
                            color: manager.currentMode.color
                        )
                    }

                    ControlButtonsView()
                        .padding(.vertical, 10)
                }
                .frame(maxWidth: 230)

                if settings.operatingMode == .single {
                    ModePickerView()
                        .padding(.bottom, 10)
                }

                Spacer()

                StatsAndSettingsView()
                    .padding(.bottom, 5)
            }
            .padding(.horizontal)
            .padding(.top, 25)
            .padding(.bottom)
            .frame(width: 320, height: 500)

            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(10)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settings)
                    .fixedSize()
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    manager.currentMode.color.opacity(0.4),
                    Color(nsColor: NSColor.controlBackgroundColor).opacity(0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .animation(.easeInOut(duration: 0.5), value: manager.currentMode)
        )
        .preferredColorScheme({
            switch settings.colorTheme {
                case .light: return .light
                case .dark: return .dark
                case .system: return nil // Use system default
            }
        }())
    }
}
