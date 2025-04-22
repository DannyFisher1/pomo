import SwiftUI

struct RingTimerView: View {
    @Binding var timeRemaining: Int
    let totalTime: Int
    let color: Color

    var progress: CGFloat {
        let rawProgress = 1 - (CGFloat(timeRemaining) / CGFloat(max(1, totalTime)))
        return max(0, min(1, rawProgress))
    }

    var minutes: Int { timeRemaining / 60 }
    var seconds: Int { timeRemaining % 60 }

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
                Text("\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .frame(width: 130, alignment: .center)
                    .multilineTextAlignment(.center)
                    .fixedSize()
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
