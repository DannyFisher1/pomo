# Pomo 🍅 - The Elegant Pomodoro Timer for macOS

[![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-orange.svg)](https://developer.apple.com/xcode/swiftui/)
[![macOS](https://img.shields.io/badge/macOS-12.0%2B-blue.svg)](https://www.apple.com/macos)

Pomo is a minimalist yet powerful Pomodoro timer designed specifically for macOS. It lives discreetly in your status bar, providing easy access to focus sessions and break reminders without cluttering your workspace. Built entirely with SwiftUI, it offers a clean, modern, and customizable experience.

## ✨ Key Features

*   **Status Bar Integration:** Runs conveniently from the macOS status bar, showing the current mode icon and remaining time (HH:MM:SS or MM:SS).
*   **Flexible Timer Modes:**
    *   **Single Cycle:** Run a single Pomodoro, short break, or long break.
    *   **Repeat Mode:** Continuously repeat a selected timer mode (Pomodoro, Short, or Long Break).
    *   **Routine Mode:** Follow predefined or custom sequences of work and break intervals.
*   **Customizable Durations:** Set precise durations for Pomodoro, Short Break, and Long Break intervals using Hours, Minutes, and Seconds (e.g., 1h 30m 0s).
*   **Routine Management:**
    *   Comes with standard routines (e.g., "Standard Pomodoro (4x)", "Pomodoro -> Short Break").
    *   Create, edit, and delete your own custom work/break routines via the Settings panel.
*   **Elegant Interface:**
    *   Clean popover window accessible from the status bar.
    *   Animated ring timer visually representing progress.
    *   Dynamic background gradients matching the current timer mode.
*   **Interactive Controls:**
    *   Standard Start/Pause functionality.
    *   **Smart Reset/Skip Button:**
        *   **Skip:** Skips the current interval when the timer is running (with a subtle press animation).
        *   **Soft Reset (Tap):** Resets the timer for the *current* interval/step when paused.
        *   **Hard Reset (Long Press):** Hold the reset button for ~1 second to reset the *entire* current routine or cycle sequence (includes a satisfying animated outline and completion pop).
        *   **Header Animation:** Visual feedback in the header when a full (hard) reset occurs.
*   **Customization Options:**
    *   **Appearance:** Light, Dark, or System theme.
    *   **Icons:** Customize the status bar icons for Pomodoro, Short Break, and Long Break using any emoji.
    *   **Sounds:** Toggle completion sounds on/off and choose from different sound options.
    *   **Notifications:** Toggle desktop notifications on/off.
    *   **Custom Alerts:** Uses custom, visually appealing alert windows instead of standard system notifications. Adjust alert size and duration.
*   **Settings Management:** Easily reset all settings to their defaults.

## 📸 Screenshots

*(Include screenshots here if possible)*

*   `[Screenshot of Status Bar Item]`
*   `[Screenshot of Main Popover Window - Ring Timer]`
*   `[Screenshot of Settings Panel - Timer Durations]`
*   `[Screenshot of Settings Panel - Routine Management]`
*   `[GIF of Long-press Reset Animation]`

## 💻 Technology Stack

*   **SwiftUI:** Modern declarative UI framework for macOS.
*   **Combine:** Used for reactive handling of settings changes and timer state.
*   **AppKit:** Integrated for specific macOS features like `NSStatusBar`, `NSPopover`, `NSSound`, and custom windows.
*   **Swift:** Language used for development.

## 🚀 Getting Started

### Prerequisites

*   macOS 12.0 or later
*   Xcode 13 or later

### Building & Running

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd pomo
    ```
2.  **Open in Xcode:**
    Open the `pomo.xcodeproj` file in Xcode.
3.  **Build and Run:**
    Select the "pomo" target and choose "My Mac" as the run destination. Press the Run button (Cmd+R) or select Product > Run from the menu.

The Pomo icon will appear in your macOS status bar.

## ⚙️ Usage

1.  **Click the status bar icon:** This opens the main popover window.
2.  **Select Operating Mode (Settings):** Go to Settings (gear icon) > Behavior > Timer Mode to choose between Single Cycle, Repeat Mode, or Follow Routine.
3.  **Start/Pause:** Use the main colored button in the popover.
4.  **Skip/Reset:**
    *   **While Running:** The secondary button shows "Skip". Click to end the current interval and move to the next (or stop if in Single mode).
    *   **While Paused:** The secondary button shows "Reset".
        *   **Tap:** Resets the timer for the current interval.
        *   **Hold:** Press and hold for ~1 second to reset the entire routine/cycle sequence (visual feedback provided).
5.  **Change Mode (Single Cycle Only):** If in Single Cycle mode, buttons appear below the timer to switch between Pomodoro, Short Break, and Long Break manually.
6.  **Access Settings:** Click the gear icon (⚙️) in the top-right corner of the popover.
7.  **Customize Durations:** In Settings > Timer Durations, click a row (e.g., "Pomodoro") to open a sheet where you can adjust hours, minutes, and seconds.
8.  **Manage Routines:** In Settings > Active Routine, click "Manage Routines..." to add, edit, or delete custom timer sequences.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an Issue for bugs, feature requests, or improvements.

*(Add specific contribution guidelines if desired)*

## 📄 License

*(Specify license, e.g., MIT License)* 