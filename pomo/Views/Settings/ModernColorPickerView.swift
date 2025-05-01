import SwiftUI
import Combine

struct ModernColorPickerView: View {
    @Binding var selectedColor: Color // Represents opaque color
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Primary HSB State
    @State private var hue: Double = 0.0
    @State private var saturation: Double = 0.0 // Start saturation at 0 for center
    @State private var brightness: Double = 1.0

    // --- UI State ---
    // Wheel State
    @State private var wheelKnobPos: CGPoint = .zero
    @State private var isDraggingWheel: Bool = false
    @State private var wheelSize: CGFloat = 230 // Adjusted size for wheel
    @State private var wheelIndicatorColor: Color = .white

    // Brightness Slider State
    @State private var brightnessSliderPos: CGFloat = 0.0
    @State private var isDraggingBrightness: Bool = false
    @State private var brightnessSliderProxy: GeometryProxy? = nil
    private let brightnessSliderHeight: CGFloat = 28
    private let brightnessSliderTrackHeight: CGFloat = 10
    private var brightnessSliderWidth: CGFloat { wheelSize } // Match wheel width
    private var brightnessKnobSize: CGFloat { brightnessSliderHeight }

    // Text Field State (remains the same)
    @State private var hexString: String = "#FFFFFF"
    @State private var rString: String = "255"
    @State private var gString: String = "255"
    @State private var bString: String = "255"
    // HSB fields are less common with wheel pickers, can be added if needed

    // Debouncer for text input
    @State private var textUpdateDebouncer = PassthroughSubject<Void, Never>()

    // --- Constants ---
    private let previewSize: CGFloat = 40
    private let cornerRadius: CGFloat = 10
    private let spacing: CGFloat = 12
    private let mainPickerSpacing: CGFloat = 15
    private let shadowOpacity: Double = 0.10
    private let strongShadowOpacity: Double = 0.18
    private let textFieldWidth: CGFloat = 40


    // --- Calculated Properties ---
    private var calculatedSelectedColor: Color { Color(hue: hue, saturation: saturation, brightness: brightness) }
    // Hue/Sat part of the color at max brightness (for slider gradient)
    private var hueSatColor: Color { Color(hue: hue, saturation: saturation, brightness: 1.0) }
    private var defaultBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.99)
    }
    private var textFieldBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.04)
    }
    private var secondaryTextColor: Color { .secondary }

    var body: some View {
        VStack(spacing: mainPickerSpacing) { // Use main spacing for major elements
            colorWheel
                .frame(width: wheelSize, height: wheelSize)

            brightnessSlider
                .frame(width: brightnessSliderWidth, height: brightnessSliderHeight)

            valueInputFields
                .padding(.vertical, spacing * 0.5)

            HStack(spacing: 10) {
                finalPreviewSwatch
                Spacer()
                doneButton
            }
        }
        .padding(18)
        .frame(maxWidth: 300) // Keep max width constraint
        .background(defaultBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(shadowOpacity), radius: 12, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(.primary.opacity(0.1), lineWidth: 0.8)
        )
        .onAppear { setupInitialStateFromSelectedColor() }
        // Update Color from HSB changes
        .onChange(of: hue) { _, _ in handleHSBChange() }
        .onChange(of: saturation) { _, _ in handleHSBChange() }
        .onChange(of: brightness) { _, _ in handleHSBChange() }
        // Update internal HSB state if bound color changes externally
        .onChange(of: selectedColor) { _, newColor in
            if !isDraggingWheel && !isDraggingBrightness {
                if !newColor.isApproximatelyEqual(to: calculatedSelectedColor) {
                    print("External color change detected, updating internal state.")
                    setupInitialStateFromSelectedColor(color: newColor)
                }
                updateTextFieldsFromHSB(sourceColor: newColor)
            }
        }
        // Debounce text field updates
        .onReceive(textUpdateDebouncer.debounce(for: .milliseconds(400), scheduler: RunLoop.main)) { _ in
             print("Debouncer fired, updating color from text fields.")
             updateColorFromTextFields()
        }
    }

    // MARK: - Subviews: Color Wheel

    private var colorWheel: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2

            // --- Draw the filled color wheel (Hue/Saturation @ Brightness=1.0) ---
            // This is a simplified approach; performance can be improved.
             let step = 1.0 // Draw larger steps for better performance
             for y in stride(from: 0, to: size.height, by: step) {
                 for x in stride(from: 0, to: size.width, by: step) {
                     let point = CGPoint(x: x, y: y)
                     let dx = point.x - center.x
                     let dy = point.y - center.y
                     let distance = sqrt(dx*dx + dy*dy)

                     // Only draw points within the circle
                     if distance <= radius {
                         let angle = atan2(dy, dx)
                         let currentHue = (angle < 0 ? angle + 2 * .pi : angle) / (2 * .pi)
                         let currentSaturation = min(1.0, max(0.0, distance / radius))

                         context.fill(
                             Path(CGRect(x: x, y: y, width: step, height: step)), // Draw small squares
                             with: .color(Color(hue: currentHue, saturation: currentSaturation, brightness: 1.0))
                         )
                     }
                 }
             }

            // --- Draw the draggable indicator knob ---
            let knobRadius = wheelSize * 0.05 // Size relative to wheel
            let knobRect = CGRect(
                x: wheelKnobPos.x - knobRadius / 2,
                y: wheelKnobPos.y - knobRadius / 2,
                width: knobRadius,
                height: knobRadius
            )
            let knobPath = Path(ellipseIn: knobRect)

            // Draw knob fill (using the fully selected color)
            context.fill(knobPath, with: .color(calculatedSelectedColor))

            // Draw knob stroke (border)
            let indicatorStrokeStyle = StrokeStyle(lineWidth: 1.5)
            context.stroke(knobPath, with: .color(wheelIndicatorColor), style: indicatorStrokeStyle)

        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDraggingWheel = true
                    updateHueSaturation(at: value.location, size: CGSize(width: wheelSize, height: wheelSize))
                    // Implicit update via onChange listeners
                }
                .onEnded { _ in
                    isDraggingWheel = false
                    // Ensure final update
                    updateSelectedColorBinding()
                }
        )
        .onAppear {
            // Calculate initial knob position after view appears and HSB is set
            updateWheelKnobPosition(size: CGSize(width: wheelSize, height: wheelSize))
            updateIndicatorColor()
        }
         // Update knob position if H/S change externally or via text fields
        .onChange(of: hue) { _, _ in if !isDraggingWheel { updateWheelKnobPosition(size: CGSize(width: wheelSize, height: wheelSize)) } }
        .onChange(of: saturation) { _, _ in if !isDraggingWheel { updateWheelKnobPosition(size: CGSize(width: wheelSize, height: wheelSize)) } }
    }

    // MARK: - Subviews: Brightness Slider (Horizontal)

    private var brightnessSlider: some View {
        GeometryReader { geometry in
            let dragGesture = DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    isDraggingBrightness = true
                    let newPos = max(0, min(gesture.location.x, geometry.size.width))
                    brightnessSliderPos = newPos
                    if geometry.size.width > 0 {
                        // Clamp brightness slightly above 0
                        brightness = max(0.001, min(1.0, newPos / geometry.size.width))
                    }
                     // Implicit update via onChange listener
                }
                .onEnded { _ in
                    isDraggingBrightness = false
                     // Ensure final update
                    updateSelectedColorBinding()
                }

            ZStack(alignment: .leading) {
                // Track Gradient: Black to Current Hue/Sat Color
                LinearGradient(
                    gradient: Gradient(colors: [.black, hueSatColor]),
                    startPoint: .leading, endPoint: .trailing
                )
                .mask { Capsule().frame(height: brightnessSliderTrackHeight) }
                .frame(height: brightnessSliderTrackHeight)
                .overlay(Capsule().stroke(.primary.opacity(0.1), lineWidth: 0.5))
                .shadow(color: .black.opacity(shadowOpacity * 0.5), radius: 1, y: 0.5)
                .gesture(dragGesture) // Apply gesture to the track area

                // Knob
                Circle()
                     // Use the fully selected color for the knob fill
                    .fill(calculatedSelectedColor)
                    .frame(width: brightnessKnobSize, height: brightnessKnobSize)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.8), lineWidth: 1.5).shadow(radius: 1))
                    .shadow(color: .black.opacity(strongShadowOpacity), radius: 3, y: 1)
                    .position(
                        x: max(brightnessKnobSize / 2, min(brightnessSliderPos, geometry.size.width - brightnessKnobSize / 2)),
                        y: geometry.size.height / 2 // Center vertically
                    )
                    .allowsHitTesting(false) // Knob follows drag on track
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                brightnessSliderProxy = geometry
                 // Set initial slider position
                updateBrightnessSliderPosition(width: geometry.size.width)
            }
             // Update position if width changes
            .onChange(of: geometry.size.width) { _, newWidth in
                updateBrightnessSliderPosition(width: newWidth)
            }
             // Update position if brightness changes externally or via text
            .onChange(of: brightness) { _, _ in
                if !isDraggingBrightness, let width = brightnessSliderProxy?.size.width {
                    updateBrightnessSliderPosition(width: width)
                }
            }
        }
    }

    // MARK: - Subviews: Value Inputs (Unchanged)
     private var valueInputFields: some View {
         // This part remains largely the same as before
        VStack(alignment: .leading, spacing: 6) {
            // HEX Row
            HStack {
                Text("HEX")
                    .font(.system(size: 11)).foregroundColor(secondaryTextColor)
                    .frame(width: 30, alignment: .leading)

                TextField("#RRGGBB", text: $hexString)
                    .font(.system(size: 12, design: .monospaced))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 6).padding(.vertical, 5)
                    .background(textFieldBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius / 2))
                    .onChange(of: hexString) { _, newValue in
                        let cleanHex = newValue.uppercased().filter { "0123456789ABCDEF".contains($0) }.prefix(6)
                        let prefixedHex = "#" + cleanHex
                        if prefixedHex != hexString { hexString = prefixedHex }
                        textUpdateDebouncer.send()
                    }
                    .onSubmit { updateColorFromTextFields() }

                Button { copyHex() } label: {
                    Image(systemName: "doc.on.doc").font(.system(size: 11))
                        .foregroundColor(secondaryTextColor)
                }
                .buttonStyle(.plain).padding(.leading, 2)
            }

            // RGB Row
            HStack(spacing: 6) {
                Text("RGB")
                    .font(.system(size: 11)).foregroundColor(secondaryTextColor)
                    .frame(width: 30, alignment: .leading)
                valueTextField(label: "R", value: $rString, range: 0...255)
                valueTextField(label: "G", value: $gString, range: 0...255)
                valueTextField(label: "B", value: $bString, range: 0...255)
                Spacer()
            }
        }
    }

    // Reusable Text Field (Unchanged)
    private func valueTextField(label: String, value: Binding<String>, range: ClosedRange<Int>, suffix: String? = nil) -> some View {
        HStack(spacing: 2) {
            TextField(label, text: value)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .textFieldStyle(PlainTextFieldStyle())
                .frame(width: textFieldWidth)
                .padding(.vertical, 5).padding(.leading, 5)
                .padding(.trailing, suffix != nil ? 1 : 5)
                .background(textFieldBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius / 2))
                .onChange(of: value.wrappedValue) { _, _ in textUpdateDebouncer.send() }
                .onSubmit { updateColorFromTextFields() }

            if let suffix = suffix {
                Text(suffix)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(secondaryTextColor.opacity(0.8))
                    .padding(.trailing, 5)
            }
        }
    }

    // MARK: - Subviews: Bottom Row (Unchanged)
    private var finalPreviewSwatch: some View {
        calculatedSelectedColor
            .frame(width: previewSize, height: previewSize)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius / 2))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius / 2).stroke(.primary.opacity(0.15), lineWidth: 1.0))
            .shadow(color: calculatedSelectedColor.opacity(strongShadowOpacity * 0.6), radius: 2, y: 1)
    }

    private var doneButton: some View {
        Button("Done") { dismiss() }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .tint(adaptiveButtonTint())
            .shadow(color: calculatedSelectedColor.opacity(shadowOpacity), radius: 4, y: 1)
            .keyboardShortcut(.defaultAction)
    }


    // MARK: - Core Logic & Helper Functions

    // Central handler for HSB state changes from sliders/wheel
    private func handleHSBChange() {
        // Avoid recursive updates if triggered by external binding change
        if isDraggingWheel || isDraggingBrightness {
             updateSelectedColorBinding()
        }
        // Always update indicator colors and text fields based on the latest HSB
        updateIndicatorColor()
        updateTextFieldsFromHSB()
    }


    // Setup internal state from the @Binding color
    private func setupInitialStateFromSelectedColor(color initialColor: Color? = nil) {
        let targetColor = initialColor ?? selectedColor
        let nsColor = NSColor(targetColor)
        var cgHue: CGFloat = 0, cgSat: CGFloat = 0, cgBri: CGFloat = 0, cgAlp: CGFloat = 0

        if let rgbColor = nsColor.usingColorSpace(.sRGB) {
            rgbColor.getHue(&cgHue, saturation: &cgSat, brightness: &cgBri, alpha: &cgAlp)

            let minBrightSat: Double = 0.001 // Prevent pure black/white initial state issues

            hue = Double(cgHue)
            saturation = max(minBrightSat, Double(cgSat)) // Clamp sat away from 0
            brightness = max(minBrightSat, Double(cgBri)) // Clamp bright away from 0

            let clampedColor = Color(hue: hue, saturation: saturation, brightness: brightness)
            if !clampedColor.isApproximatelyEqual(to: targetColor) {
                print("Initial color potentially clamped, updating binding.")
                DispatchQueue.main.async { selectedColor = clampedColor }
            }

            // Update UI elements based on initial HSB
            updateWheelKnobPosition(size: CGSize(width: wheelSize, height: wheelSize))
            if let width = brightnessSliderProxy?.size.width {
                 updateBrightnessSliderPosition(width: width)
            } else {
                 // Estimate initial position if proxy not ready
                 updateBrightnessSliderPosition(width: brightnessSliderWidth)
            }
            updateIndicatorColor()
            updateTextFieldsFromHSB(sourceColor: clampedColor) // Sync text fields
        } else {
            print("Warning: Could not convert selected color to sRGB for initial setup.")
            // Set defaults? Or leave as they were? Let's default
            hue = 0.0
            saturation = 0.0 // Center of wheel
            brightness = 1.0 // Full brightness
            updateWheelKnobPosition(size: CGSize(width: wheelSize, height: wheelSize))
             if let width = brightnessSliderProxy?.size.width {
                 updateBrightnessSliderPosition(width: width)
             } else {
                 updateBrightnessSliderPosition(width: brightnessSliderWidth)
             }
            updateIndicatorColor()
            updateTextFieldsFromHSB()
        }
    }

    // Update the @Binding and sync text fields
    private func updateSelectedColorBinding() {
        let newColor = calculatedSelectedColor
        if !newColor.isApproximatelyEqual(to: selectedColor) {
             DispatchQueue.main.async {
                 selectedColor = newColor
                 print("Internal change updated selectedColor binding: \(newColor)")
             }
        }
         // Sync text fields immediately after internal HSB change
        updateTextFieldsFromHSB()
    }

    // --- Update UI Element Positions ---

    // Calculate and set the position of the knob on the color wheel
    private func updateWheelKnobPosition(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2
        let angle = hue * 2 * .pi
        let distance = saturation * radius

        // Convert polar (angle, distance) to Cartesian (x, y)
        // Angle 0 is typically to the right (positive x-axis) in atan2/trig functions
        // Adjust if your hue mapping starts elsewhere (e.g., red at the top)
        // Assuming Hue 0 (Red) is at angle 0 (right):
        let knobX = center.x + distance * cos(angle)
        let knobY = center.y + distance * sin(angle)

        wheelKnobPos = CGPoint(x: knobX, y: knobY)
        // print("Updated WheelKnobPos to: \(wheelKnobPos) based on H: \(hue), S: \(saturation)")
    }

    // Calculate and set the position of the knob on the brightness slider
    private func updateBrightnessSliderPosition(width: CGFloat) {
        guard width > 0 else { return }
        brightnessSliderPos = brightness * width
         // print("Updated BrightnessSliderPos to: \(brightnessSliderPos) based on B: \(brightness)")
    }

    // --- Indicator Color Logic ---
    private func updateIndicatorColor() {
        // Use the same logic as before for determining contrast
        let nsColor = NSColor(calculatedSelectedColor)
        if let rgbColor = nsColor.usingColorSpace(.sRGB) {
            let luminance = (0.2126 * rgbColor.redComponent) + (0.7152 * rgbColor.greenComponent) + (0.0722 * rgbColor.blueComponent)
            wheelIndicatorColor = luminance > 0.55 ? Color.black.opacity(0.75) : Color.white.opacity(0.9)
        } else {
            // Fallback based on brightness
            wheelIndicatorColor = brightness > 0.6 ? Color.black.opacity(0.75) : Color.white.opacity(0.9)
        }
    }

    // --- Update HSB from UI Interactions ---

    // Update Hue and Saturation based on drag location within the wheel
    private func updateHueSaturation(at location: CGPoint, size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2

        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx*dx + dy*dy)

        // Calculate Saturation (clamped 0-1, slightly above 0)
        let newSaturation = max(0.001, min(1.0, distance / radius))

        // Calculate Hue (angle)
        var angle = atan2(dy, dx) // Radians, -pi to pi
        if angle < 0 { angle += 2 * .pi } // Convert to 0 to 2pi
        let newHue = angle / (2 * .pi) // Normalize to 0-1

        // Update state if changed significantly
        let tolerance = 0.001
        var changed = false
        if abs(newHue - hue) > tolerance {
            hue = newHue
            changed = true
        }
        if abs(newSaturation - saturation) > tolerance {
            saturation = newSaturation
            changed = true
        }

        // Update visual knob position immediately for responsiveness during drag
        wheelKnobPos = location // Use raw location for visual knob

        // Trigger binding update if state actually changed
        if changed {
            updateSelectedColorBinding()
        } else {
            // If state didn't change (e.g., dragging outside radius), still update indicator
             updateIndicatorColor()
        }
    }


    // --- Text Field Logic (Mostly Unchanged) ---
    private func updateTextFieldsFromHSB(sourceColor: Color? = nil) {
        let colorToDisplay = sourceColor ?? calculatedSelectedColor
        let nsColor = NSColor(colorToDisplay)
        var shouldUpdateHex = true, shouldUpdateRGB = true

        // Optional: Add checks to prevent unnecessary updates if text already matches
        if let currentParsedHex = parseHex(hexString), currentParsedHex.isApproximatelyEqual(to: colorToDisplay, tolerance: 0.005) {
             shouldUpdateHex = false
         }
         if let r = Int(rString), let g = Int(gString), let b = Int(bString),
            let currentParsedRGB = parseRGB(r,g,b), currentParsedRGB.isApproximatelyEqual(to: colorToDisplay, tolerance: 0.005) {
             shouldUpdateRGB = false
         }

        if let rgbColor = nsColor.usingColorSpace(.sRGB) {
            if shouldUpdateHex || shouldUpdateRGB {
                let r = Int(round(rgbColor.redComponent * 255))
                let g = Int(round(rgbColor.greenComponent * 255))
                let b = Int(round(rgbColor.blueComponent * 255))
                let newHexString = String(format: "#%02X%02X%02X", r, g, b)

                if shouldUpdateHex && hexString != newHexString { hexString = newHexString }
                if shouldUpdateRGB {
                    let newR = String(r); let newG = String(g); let newB = String(b)
                    if rString != newR { rString = newR }
                    if gString != newG { gString = newG }
                    if bString != newB { bString = newB }
                }
            }
            // HSB fields could be updated here if they were visible
        } else {
            if shouldUpdateHex { hexString = "#------" }
            if shouldUpdateRGB { rString = "---"; gString = "---"; bString = "---" }
        }
    }

    private func updateColorFromTextFields() {
        var colorChanged = false
        var successfullyParsedColor: Color? = nil

        if let colorFromHex = parseHex(hexString) {
             if updateHSB(from: colorFromHex) {
                 colorChanged = true
                 successfullyParsedColor = colorFromHex
             }
        } else if let r = Int(rString), let g = Int(gString), let b = Int(bString), let colorFromRGB = parseRGB(r, g, b) {
             if updateHSB(from: colorFromRGB) {
                 colorChanged = true
                 successfullyParsedColor = colorFromRGB
             }
        }
        // Add HSB parsing here if those fields are visible

        if colorChanged, let _ = successfullyParsedColor {
            print("Color changed from text input, updating binding and UI.")
            // State (hue, sat, bright) was updated by updateHSB

             // Apply clamping after parsing text input too
            let minBrightSat: Double = 0.001
            let needsClamping = saturation < minBrightSat || brightness < minBrightSat
            if needsClamping {
                saturation = max(minBrightSat, saturation)
                brightness = max(minBrightSat, brightness)
                print("Clamping color parsed from text input.")
            }

            updateSelectedColorBinding() // Update binding with potentially re-clamped HSB
            // Update UI elements based on new HSB
            updateWheelKnobPosition(size: CGSize(width: wheelSize, height: wheelSize))
            if let width = brightnessSliderProxy?.size.width {
                 updateBrightnessSliderPosition(width: width)
            }
            updateIndicatorColor()
            // Re-sync all text fields shortly after
            DispatchQueue.main.async { updateTextFieldsFromHSB() }
        } else {
             print("Text input parsed, but no change detected or parsing failed.")
             updateTextFieldsFromHSB() // Sync back to current valid state
        }
    }


    // Helper to update internal HSB from a valid Color, returns true if changed
    @discardableResult
    private func updateHSB(from color: Color) -> Bool {
        let nsColor = NSColor(color)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else { return false }
        var cgHue: CGFloat = 0, cgSat: CGFloat = 0, cgBri: CGFloat = 0, cgAlp: CGFloat = 0
        rgbColor.getHue(&cgHue, saturation: &cgSat, brightness: &cgBri, alpha: &cgAlp)

        let tolerance = 0.001
        // Clamp incoming Sat/Bright slightly away from pure 0
        let newSat = max(0.001, Double(cgSat))
        let newBri = max(0.001, Double(cgBri))
        let newHue = Double(cgHue)

        let didChangeHue = abs(hue - newHue) > tolerance
        let didChangeSat = abs(saturation - newSat) > tolerance
        let didChangeBri = abs(brightness - newBri) > tolerance

        if didChangeHue { hue = newHue }
        if didChangeSat { saturation = newSat }
        if didChangeBri { brightness = newBri }

        return didChangeHue || didChangeSat || didChangeBri
    }


    // --- Utility Functions (Unchanged) ---
    private func copyHex() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hexString, forType: .string)
        #elseif os(iOS)
        // UIPasteboard is not available on macOS
        // Consider platform-specific implementation or remove for macOS only
        print("Copying not implemented for this platform in preview.")
        #endif
        print("Copied: \(hexString)")
    }
    private func adaptiveButtonTint() -> Color {
        let nsColor = NSColor(calculatedSelectedColor)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else { return .accentColor }
        let luminance = (0.2126 * rgbColor.redComponent) + (0.7152 * rgbColor.greenComponent) + (0.0722 * rgbColor.blueComponent)
        if luminance > 0.6 || luminance < 0.15 { return .accentColor }
        return calculatedSelectedColor
    }

} // End of ModernColorPickerView struct





// --- Unchanged Placeholder Implementations for brevity ---
extension ModernColorPickerView {
    private func parseHex(_ hex: String) -> Color? {
         let cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).dropFirst(hex.hasPrefix("#") ? 1 : 0)
         guard cleanHex.count == 6, let hexValue = UInt64(cleanHex, radix: 16) else { return nil }
         let r = Double((hexValue & 0xFF0000) >> 16) / 255.0
         let g = Double((hexValue & 0x00FF00) >> 8) / 255.0
         let b = Double(hexValue & 0x0000FF) / 255.0
         guard (0.0...1.0).contains(r), (0.0...1.0).contains(g), (0.0...1.0).contains(b) else { return nil }
         return Color(red: r, green: g, blue: b)
     }
     private func parseRGB(_ r: Int, _ g: Int, _ b: Int) -> Color? {
         guard (0...255).contains(r), (0...255).contains(g), (0...255).contains(b) else { return nil }
         return Color(red: Double(r) / 255.0, green: Double(g) / 255.0, blue: Double(b) / 255.0)
     }
    
}

extension Color {
    func isApproximatelyEqual(to other: Color, tolerance: Double = 0.001) -> Bool {
        let nsSelf = NSColor(self.opacity(1.0)); let nsOther = NSColor(other.opacity(1.0))
        guard let rgbSelf = nsSelf.usingColorSpace(.sRGB), let rgbOther = nsOther.usingColorSpace(.sRGB) else { return self == other }
        return abs(rgbSelf.redComponent - rgbOther.redComponent) < CGFloat(tolerance) &&
               abs(rgbSelf.greenComponent - rgbOther.greenComponent) < CGFloat(tolerance) &&
               abs(rgbSelf.blueComponent - rgbOther.blueComponent) < CGFloat(tolerance)
    }
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted); var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int); let r, g, b: UInt64
        switch hex.count {
        case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:(r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1.0)
    }
}
