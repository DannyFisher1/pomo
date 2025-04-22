import AppKit
import SwiftUI
import Combine

class CustomAlertWindowController: NSWindowController, NSWindowDelegate {
    private var dismissTimer: Timer?
    private var dismissDelay: TimeInterval // Store duration
    
    // Keep track of controllers to prevent them from being deallocated immediately
    // And manage stacking
    static var activeAlerts: [CustomAlertWindowController] = []
    private static let alertSpacing: CGFloat = 10 // Vertical space between alerts

    // New DESIGNATED Initializer
    init(title: String, message: String, appIcon: NSImage, scale: Double, duration: Double) {
        // 1. Initialize self properties BEFORE super.init
        self.dismissDelay = duration
        
        // 2. Create content view and controller
        let alertView = CustomAlertView(title: title, message: message, appIcon: appIcon, scale: scale)
        let hostingController = NSHostingController(rootView: alertView)
        // Create a temporary window reference for super.init
        let window = NSWindow(contentViewController: hostingController)

        // 3. Call super.init with the created window
        super.init(window: window)
        
        // --- Configuration AFTER super.init --- 
        
        // Calculate scaled width (use the base width from CustomAlertView)
        let baseWidth: CGFloat = 350 // Match the maxWidth used in CustomAlertView
        let scaledWidth = baseWidth * scale
        // Set the CONTENT size - width is scaled, height starts minimal
        self.window?.setContentSize(NSSize(width: scaledWidth, height: 1)) 
        
        // 4. Configure the window AFTER super.init and setting size
        self.window?.styleMask = [.borderless]
        self.window?.level = .floating // Keep on top
        self.window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary] // Show on all spaces
        self.window?.isOpaque = false
        self.window?.backgroundColor = .clear
        self.window?.hasShadow = false // Shadow is handled by the SwiftUI view
        self.window?.ignoresMouseEvents = true // Click-through
        self.window?.animationBehavior = .utilityWindow // Less aggressive animation
        
        // 5. Set delegate
        self.window?.delegate = self
    }
    
    // Required initializer for NSWindowController conformance when providing a custom init
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Show the window, position it, and start the dismiss timer
    func show() {
        // Use self.window here, which is guaranteed to exist after init
        guard let window = self.window, 
              let screen = NSScreen.main, 
              let hostingView = window.contentViewController?.view else { // Get hosting view
            print("Error: Could not get window, screen, or hosting view.") 
            return
        }
        
        print("--- Showing Custom Alert ---")
        print("Screen Visible Frame: \(screen.visibleFrame)")

        // Add self to the static list *before* calculating position
        Self.activeAlerts.append(self)

        // Width is known from init's setContentSize
        let windowWidth = window.frame.size.width
        print("Initial Window Width (set in init): \(windowWidth)") 
        
        // Calculate ACTUAL required height from content
        let fittingSize = hostingView.fittingSize
        // Recalculate height based on fitting size, provide scaled fallback
        let scale = windowWidth / 350 // Infer scale from width
        let calculatedHeight = fittingSize.height > 1 ? fittingSize.height : 65 * scale // Use fitting height if > 1, else scaled default
        print("Fitting Size: \(fittingSize), Using Height: \(calculatedHeight)")

        let screenFrame = screen.visibleFrame // Use visible frame to avoid menu bar/dock
        
        // Calculate vertical position based on existing alerts AND FITTING HEIGHT
        let totalExistingHeight = Self.activeAlerts.dropLast().reduce(0) { 
            $0 + ($1.window?.frame.height ?? 0) + Self.alertSpacing 
        }
        print("Total Existing Height Offset: \(totalExistingHeight)")
        
        // Calculate origin for the BOTTOM-LEFT corner of the window
        let originX = screenFrame.origin.x + screenFrame.size.width - windowWidth - 20 
        let originY = screenFrame.origin.y + screenFrame.size.height - calculatedHeight - 20 - totalExistingHeight 
        print("Calculated Origin (Bottom-Left): (X: \(originX), Y: \(originY))") 

        // Set the frame explicitly *before* showing
        // window.setFrameOrigin(NSPoint(x: originX, y: originY)) // REMOVED setFrameOrigin
        window.setFrame(NSRect(x: originX, y: originY, width: windowWidth, height: calculatedHeight), display: false)
        print("Window frame set to: \(window.frame)")
        
        window.orderFront(nil) // Show the window
        print("Window ordered front.")
        
        // Start the timer to auto-dismiss
        dismissTimer?.invalidate()
        print("Scheduling dismiss timer for \(dismissDelay) seconds...")
        dismissTimer = Timer.scheduledTimer(withTimeInterval: dismissDelay, repeats: false) { [weak self] _ in
            print("Dismiss timer fired. Calling closeAnimated.") // Log timer firing
            self?.closeAnimated()
        }
    }
    
    // Animate closing
    private func closeAnimated() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3 // Adjust animation duration as needed
            self.window?.animator().alphaValue = 0
        }, completionHandler: {
            self.close() // Use the standard close method after animation
        })
    }

    // Ensure timer is invalidated and remove from static list when closed
    func windowWillClose(_ notification: Notification) {
        dismissTimer?.invalidate()
        // Remove self from the static list
        Self.activeAlerts.removeAll { $0 === self }
        // Re-position remaining alerts (optional, could be complex)
        // For simplicity, we won't reposition here, new alerts will stack correctly.
    }
    
    // Override to prevent deallocation if window is created but not shown immediately
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        // If shown via this method, ensure positioning and timer are set
        if dismissTimer == nil { // Basic check if our show() was already called
            show()
        }
    }
} 