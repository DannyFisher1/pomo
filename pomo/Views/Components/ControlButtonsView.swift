//
//  ControlButtonsView.swift
//  pomo
//
//  Created by Danny Fisher on 4/21/25.
//
import SwiftUI

// Extracted Label for easier gesture application and state management
struct ResetButtonLabelView: View {
    @EnvironmentObject var manager: PomodoroManager
    @EnvironmentObject var settings: TimerSettings
    @State private var isPressing = false
    @State private var longPressTimer: Timer? = nil
    @State private var longPressProgress: CGFloat = 0.0 // 0.0 to 1.0
    @State private var longPressTriggered = false
    @State private var showCompletionEffect = false // For reset completion pop
    @State private var skipButtonScale: CGFloat = 1.0 // For skip button tap scale
    let longPressDuration: TimeInterval = 1.0// Duration needed for full reset

    var body: some View {
        ZStack {
            // Base Label (Reset or Skip)
            Label(manager.isRunning ? "Skip" : "Reset",
                  systemImage: manager.isRunning ? "forward.end.fill" : "arrow.clockwise")
                .frame(maxWidth: .infinity)

            // Progress Outline Overlay (only shown during reset press)
            if isPressing && !manager.isRunning {
                // Use RoundedRectangle matching button shape
                RoundedRectangle(cornerRadius: 8) // Match button corner radius
                    .trim(from: 0, to: longPressProgress)
                    .stroke(Color.gray, lineWidth: 3)
                    // Remove fixed frame, let it size to the button
                    // .frame(width: 38, height: 38)
                    .rotationEffect(.degrees(0)) // Start drawing from the right edge (0 degrees)
                    .animation(.linear(duration: 0.1), value: longPressProgress)
                    
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44) // Keep frame on ZStack
        .contentShape(Rectangle()) // Ensure entire area is tappable
        .scaleEffect(manager.isRunning ? skipButtonScale : 1.0)
        .overlay(
            // Completion effect: quick outline flash
            RoundedRectangle(cornerRadius: 8)
                .stroke(settings.color(for: manager.currentMode).opacity(0.8), lineWidth: 3) // Use settings color
                .scaleEffect(showCompletionEffect ? 1.0 : 1.0) // Slight expansion
                .opacity(showCompletionEffect ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.2), value: showCompletionEffect) // Springy pop
        )
        // Add conditional glow for Skip press
        .shadow(
            color: manager.isRunning && skipButtonScale < 1.0 ? settings.color(for: manager.currentMode).opacity(0.6) : Color.clear, // Use settings color
            radius: manager.isRunning && skipButtonScale < 1.0 ? 6 : 0,
            x: 0, y: 2
        )
        // Animate the shadow appearance/disappearance
        .animation(.easeOut(duration: 0.15), value: skipButtonScale < 1.0) // Use the condition as the value
        .gesture(
            // Only apply complex gesture if timer is NOT running (i.e., Reset mode)
            manager.isRunning ? nil :
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                        longPressTriggered = false
                        longPressProgress = 0.0
                        startTimer()
                    }
                }
                .onEnded { _ in
                    // Stop the timer FIRST to prevent it firing after release
                    stopTimer() 
                    
                    // Now check the flag set by the timer callback
                    if !longPressTriggered {
                        // If timer finished without triggering, it's a short press
                        print("Short press detected - Resetting current step")
                        manager.reset()
                    } else {
                        // Timer must have completed, full reset already triggered by timer callback
                        // Reset the flag for the next press cycle
                        longPressTriggered = false 
                        print("Long press release detected - Full reset already triggered")
                    }
                    isPressing = false
                }
        )
        .buttonStyle(SecondaryPomodoroButtonStyle()) // Apply style here
        // If running, use a simple Button for Skip
        .simultaneousGesture(manager.isRunning ? TapGesture().onEnded { 
            manager.skipCurrentStep()
            // Trigger scale animation for skip tap
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                skipButtonScale = 0.95 // Scale down
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    skipButtonScale = 1.0 // Scale back
                }
            }
        } : nil)


    }

    func startTimer() {
        longPressTimer?.invalidate()
        longPressProgress = 0.0
        longPressTriggered = false

        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            guard isPressing else {
                timer.invalidate()
                return
            }

            longPressProgress += 0.05 / longPressDuration

            if longPressProgress >= 1.0 && isPressing && !longPressTriggered {
                timer.invalidate()
                longPressTriggered = true
                print("✅ Long press triggered - Resetting full cycle")
                manager.resetFullCycle()
                showCompletionEffect = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCompletionEffect = false
                }
            }
        }
    }


    func stopTimer() {
        // This function is now primarily called by onEnded for manual release/interruption
        longPressTimer?.invalidate()
        longPressTimer = nil
        
        // Always animate progress back to 0 visually when the timer stops manually
        // (unless the effect is showing)
        if !showCompletionEffect { // Avoid interfering with completion pop
            withAnimation(.easeOut(duration: 0.2)) {
                longPressProgress = 0.0
            }
        }
        
        // Note: longPressTriggered flag is NOT reset here.
        // It's reset in .onEnded after being checked, or remains true until next press starts.
    }
}


struct ControlButtonsView: View {
    @EnvironmentObject var manager: PomodoroManager
    @EnvironmentObject var settings: TimerSettings
    // Removed state vars as they are now in ResetButtonLabelView

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
            .buttonStyle(PomodoroButtonStyle(backgroundColor: settings.color(for: manager.currentMode)))
            .frame(maxWidth: .infinity, minHeight: 44) // Keep forced height
            
            // Skip/Reset Button - Use the new Label View
            ResetButtonLabelView()
        }
        .padding(.horizontal)
    }
}
