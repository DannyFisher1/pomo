import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var manager: PomodoroManager
    @EnvironmentObject var settings: TimerSettings
    @Environment(\.colorScheme) var systemColorScheme

    // Define a notification name
    static let openSettingsNotification = Notification.Name("dev.dannyfisher.pomo.openSettings")

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
                            color: settings.color(for: manager.currentMode)
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
            .overlay(alignment: .topTrailing) {
                // Pass the notification name to the button
                SettingsGearButton(notificationName: Self.openSettingsNotification)
            }

        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    settings.color(for: manager.currentMode).opacity(0.4),
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
                case .system: return nil
            }
        }())
    }
}

struct SettingsGearButton: View {
    // Receive the notification name
    let notificationName: Notification.Name
    @EnvironmentObject var settings: TimerSettings
    @State private var isHovered = false

    var body: some View {
        Button {
            // Post the notification when clicked
            NotificationCenter.default.post(name: notificationName, object: nil)
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.callout)
                .foregroundColor(.secondary)
                // Opacity logic: Hide only if hover-only is ON AND not hovering
                .opacity(settings.showSettingsIconOnHoverOnly && !isHovered ? 0 : 1)
        }
        .buttonStyle(.plain)
        .padding(10)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
