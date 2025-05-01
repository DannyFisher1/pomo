import SwiftUI

struct RingTimerView: View {
    @Binding var timeRemaining: TimeInterval
    let totalTime: TimeInterval
    let color: Color

    var progress: CGFloat {
        let rawProgress = 1 - (CGFloat(timeRemaining) / CGFloat(max(1.0, totalTime)))
        return max(0, min(1, rawProgress))
    }

    // Calculate hours, minutes (0-59), and seconds (0-59) from TimeInterval
    var hours: Int { Int(timeRemaining) / 3600 }
    var minutes: Int { (Int(timeRemaining) % 3600) / 60 }
    var seconds: Int { Int(timeRemaining) % 60 }

    // Computed property for the formatted time string
    var formattedTimeString: String {
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    color.opacity(0.2),
                    style: StrokeStyle(
                        lineWidth: 16,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            color,
                            color.opacity(0.7),
                            color.opacity(0.5)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(
                        lineWidth: 16,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: progress)
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)

            // Time display
            VStack(spacing: 2) {
                // Use a single Text view with the computed formatted string
                Text(formattedTimeString)
                    // Apply modifiers directly to this Text view
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .lineLimit(1) // Ensure single line
                    .minimumScaleFactor(0.7) // Allow shrinking if needed
                    .layoutPriority(1)
                    .foregroundColor(.primary)
                
                Text("remaining")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 200, height: 200)
        .padding(15)
    }
}
