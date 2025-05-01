import SwiftUI

struct ModeIndicatorView: View {
    let mode: TimerMode
    let operatingMode: TimerSettings.OperatingMode
    let routine: Routine?
    let currentStepIndex: Int

    @EnvironmentObject var manager: PomodoroManager
    @EnvironmentObject var settings: TimerSettings

    @State private var showRoutineDetails = false
    @State private var showFullList = false
    @State private var isAnimatingReset = false

    private var statusText: String {
        switch operatingMode {
        case .single:
            return "\(mode.rawValue) (Single Cycle)"
        case .cycle:
            return "\(mode.rawValue) (Repeating)"
        case .routine:
            return mode.rawValue
        }
    }

    private var nextStepText: String? {
        guard operatingMode == .routine,
              let routine = routine,
              !routine.steps.isEmpty
        else { return nil }
        let nextIndex = (currentStepIndex + 1) % routine.steps.count
        return "(Next: \(routine.steps[nextIndex].rawValue))"
    }

    private func upcomingSteps(full: Bool) -> [(index: Int, step: TimerMode)] {
        guard operatingMode == .routine,
              let steps = routine?.steps,
              steps.count > currentStepIndex + 1
        else { return [] }

        let start = currentStepIndex + 1
        let slice: [TimerMode]
        if full {
            slice = Array(steps[start...])
        } else {
            let count = min(3, steps.count - start)
            slice = Array(steps[start..<(start + count)])
        }

        return slice.enumerated()
            .map { offset, step in (index: start + offset, step: step) }
    }

    var body: some View {
        VStack(spacing: 4) {
            Button {
                showRoutineDetails.toggle()
            } label: {
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: mode.icon)
                            .foregroundColor(settings.color(for: mode))
                        Text(statusText)
                            .font(.headline.weight(.medium))
                            .lineLimit(1)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(settings.color(for: mode).opacity(0.1))
                    .clipShape(Capsule())
                    .scaleEffect(isAnimatingReset ? 1.1 : 1.0)
                    .opacity(isAnimatingReset ? 0.6 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isAnimatingReset)

                    if let next = nextStepText {
                        Text(next)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(operatingMode != .routine)
            .popover(isPresented: $showRoutineDetails, arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Upcoming in “\(routine?.name ?? "")”:")
                        .font(.caption).bold()

                    ForEach(upcomingSteps(full: showFullList), id: \.index) { item in
                        HStack {
                            Text("\(item.index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: item.step.icon)
                                .foregroundColor(settings.color(for: item.step))
                            Text(item.step.rawValue)
                                .font(.caption)
                        }
                    }
                    

                    let remainingSteps = (routine?.steps.count ?? 0) - currentStepIndex - 1
                    if remainingSteps > 3 {
                        Button(showFullList ? "Show Less" : "Show All") {
                            showFullList.toggle()
                        }
                        .font(.caption)
                        .padding(.top, 4)
                    }

                }
                .padding(10)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 3)
                .frame(maxWidth: 250)
            }
        }
        .onChange(of: manager.didPerformFullReset) { _, newValue in
            if newValue {
                isAnimatingReset = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isAnimatingReset = false
                }
            }
        }
    }
}
