# pomo

Pomo is a minimalist yet feature-rich Pomodoro timer application designed for the macOS menu bar. It helps you stay focused and manage your work/break cycles effectively using the Pomodoro Technique.

## Core Features

*   **Flexible Timer Modes:** Supports standard Pomodoro, Short Break, and Long Break cycles.
*   **Customizable Durations:** Set the exact minute duration for each timer mode via the Settings panel.
*   **Multiple Operating Modes:**
    *   **Single Cycle:** Run the currently selected mode (Pomodoro, Short, or Long) just once. Allows manual selection of which mode to run.
    *   **Repeat Mode:** Continuously repeat a specific mode (Pomodoro, Short, or Long) selected in Settings. Allows manual selection of which mode to repeat.
    *   **Follow Routine:** Automatically progress through a sequence of steps defined in a customizable routine.
*   **Routine Management:**
    *   Select from pre-defined default routines (e.g., standard 4x Pomodoro cycle).
    *   Create, edit (name, add/delete/reorder steps), and delete custom work/break routines.
*   **Elegant Status Bar Integration:**
    *   Always visible icon in the menu bar shows the current timer mode.
    *   Displays remaining time next to the icon.
    *   Customize the emoji icon for each timer mode (Pomodoro, Short Break, Long Break) in Settings.
*   **Interactive Main UI (Popover):**
    *   Circular progress ring visually represents time remaining.
    *   Clear digital time display.
    *   Dynamic Start/Pause button.
    *   Dynamic Reset/Skip button (allows resetting when paused, or skipping the current step when running).
    *   Header indicates the current timer mode.
    *   In "Follow Routine" mode, the header shows "(Next: ...)" and tapping it reveals an animated dropdown of upcoming steps.
    *   Clean display of session statistics (completed Pomodoros, Short Breaks, Long Breaks).
*   **Sounds & Notifications:**
    *   Optional sound alert upon timer completion (plays twice).
    *   Choose from various built-in system sounds, with preview in Settings.
    *   Setting available for desktop notifications (Note: *Functionality requires user permission and platform integration*).
*   **Appearance:**
    *   Adaptive Light/Dark mode based on system settings or user preference.
    *   Subtle background gradient changes color based on the active timer mode.
    *   Smooth animations for state transitions.

## How to Use

1.  Click the icon in the macOS menu bar to reveal the timer popover.
2.  Select an **Operating Mode** in **Settings -> Behavior**:
    *   `Single Cycle` or `Repeat Mode`: Choose the desired mode (Pomodoro, Short Break, Long Break) using the segmented control in the main UI *before* starting the timer.
    *   `Follow Routine`: Select the desired routine in **Settings -> Active Routine**. The segmented control in the main UI will be hidden.
3.  Click **Start** to begin the timer.
4.  Use **Pause/Resume** as needed.
5.  Use **Reset** (when paused) or **Skip** (when running) to control the flow.
6.  Access **Settings** via the gear icon in the bottom-right corner of the popover.

## Settings Explained

*   **Timer Durations:** Set minutes for Pomodoro, Short Break, Long Break.
*   **Behavior:**
    *   **Timer Mode:** Choose Single Cycle, Repeat Mode, or Follow Routine.
    *   **(If Repeat Mode): Mode to Repeat:** Select which mode (Pomodoro, Short, Long) gets repeated.
    *   **Play Sounds:** Enable/disable end-of-cycle sound alerts.
    *   **Completion Sound:** Choose the alert sound.
    *   **Show Notifications:** Enable/disable desktop notifications (requires system permission).
*   **(If Follow Routine): Active Routine:**
    *   Select the routine to follow.
    *   Click **Manage Routines...** to add, edit, or delete custom routines.
*   **Appearance:**
    *   **Theme:** Choose System, Light, or Dark mode.
    *   **Pomodoro/Short Break/Long Break Icon:** Set custom status bar emojis for each mode.
*   **Reset All Settings to Defaults:** Reverts all settings to their original values.

## Current State

The application implements all core features described above. The UI has been refined for clarity and visual appeal. Routine management provides flexibility in defining custom work/break patterns.

*(Self-Correction/Note: While the setting for notifications exists, the actual implementation of requesting permission and displaying system notifications was not explicitly added or verified in this development session and would require further platform-specific code.)*

## Future Enhancements (Ideas)

*   Implement desktop notifications.
*   Add "Skip Break" / "End Pomodoro Early" options separate from the main Skip button.
*   Visual distinction (e.g., color flash, haptic feedback) on automatic transitions between modes.
*   Ability to define custom durations *within* routine steps.
*   More sophisticated logic for determining long breaks (e.g., after every X *completed* Pomodoros within a routine).
*   Keyboard shortcuts for core actions.

---