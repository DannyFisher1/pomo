import SwiftUI

struct CustomAlertView: View {
    let title: String
    let message: String
    let appIcon: NSImage
    let scale: Double
    
    // Base sizes for scaling
    var baseIconSize: CGFloat = 32
    var baseTitleSize: CGFloat = 13
    var baseMessageSize: CGFloat = 11
    var baseHSpacing: CGFloat = 12
    var baseVSpacing: CGFloat = 2
    var basePadding: CGFloat = 10
    var cornerRadius: CGFloat = 12

    var body: some View {
        HStack(alignment: VerticalAlignment.center, spacing: baseHSpacing * scale) {
            Image(nsImage: appIcon)
                .resizable()
                .scaledToFit()
                .frame(width: baseIconSize * scale, height: baseIconSize * scale)

            VStack(alignment: .leading, spacing: baseVSpacing * scale) {
                Text(title)
                    .font(.system(size: baseTitleSize * scale, weight: .semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(message)
                    .font(.system(size: baseMessageSize * scale))
                    .foregroundColor(.primary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, basePadding * scale)
        .frame(maxWidth: 350 * scale) // Keep your existing max width
        .background(
            .ultraThickMaterial,
            in: RoundedRectangle(cornerRadius: cornerRadius * scale, style: .continuous)
        )
        .shadow(color: .black.opacity(0.2), radius: 5 * scale, y: 3 * scale)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct CustomAlertView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Test with short text
            CustomAlertView(
                title: "Short Title",
                message: "Short message that fits in one line.",
                appIcon: NSApplication.shared.applicationIconImage ?? NSImage(),
                scale: 1.0
            )
            
            // Test with long text
            CustomAlertView(
                title: "Very Long Title That Should Wrap Properly Without Truncation",
                message: "This is a much longer message that should demonstrate proper text wrapping behavior. The text should flow naturally to multiple lines instead of being truncated with ellipsis. This ensures all content remains readable regardless of length.",
                appIcon: NSApplication.shared.applicationIconImage ?? NSImage(),
                scale: 1.0
            )
            
            // Test with scaled version
            CustomAlertView(
                title: "Scaled Version",
                message: "This tests the scaling behavior with multi-line text.",
                appIcon: NSApplication.shared.applicationIconImage ?? NSImage(),
                scale: 0.8
            )
        }
        .padding()
        .frame(width: 400) // Constrain preview width
    }
}
