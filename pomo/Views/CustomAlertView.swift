import SwiftUI

struct CustomAlertView: View {
    let title: String
    let message: String
    let appIcon: NSImage
    let scale: Double
    
    // Base sizes for scaling
    var baseIconSize: CGFloat = 32
    var baseTitleSize: CGFloat = 13 // System headline size
    var baseMessageSize: CGFloat = 11 // System subheadline size
    var baseHSpacing: CGFloat = 12
    var baseVSpacing: CGFloat = 2
    var basePadding: CGFloat = 10

    var body: some View {
        HStack(spacing: baseHSpacing * scale) {
            Image(nsImage: appIcon)
                .resizable()
                .scaledToFit()
                .frame(width: baseIconSize * scale, height: baseIconSize * scale)
                .padding(.leading, basePadding * scale)
            
            VStack(alignment: .leading, spacing: baseVSpacing * scale) {
                Text(title)
                    .font(.system(size: baseTitleSize * scale))
                    .foregroundColor(.primary)
                Text(message)
                    .font(.system(size: baseMessageSize * scale))
                    .foregroundColor(.primary.opacity(0.8))
            }
            .padding(.trailing, basePadding * scale)
            
            Spacer()
        }
        .padding(.vertical, basePadding * scale)
        .background(
            .ultraThickMaterial,
            in: RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
        )
        .frame(maxWidth: 350 * scale)
        .shadow(color: .black.opacity(0.2), radius: 5 * scale, y: 3 * scale)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// Preview
struct CustomAlertView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CustomAlertView(
                title: "Pomodoro Finished!",
                message: "Did you actually work, or just stare blankly? And maybe a second line.",
                appIcon: NSApplication.shared.applicationIconImage ?? NSImage(),
                scale: 1.0
            )
            CustomAlertView(
                title: "Pomodoro Finished!",
                message: "Did you actually work, or just stare blankly? And maybe a second line.",
                appIcon: NSApplication.shared.applicationIconImage ?? NSImage(),
                scale: 0.8
            )
            CustomAlertView(
                title: "Pomodoro Finished!",
                message: "Did you actually work, or just stare blankly? And maybe a second line.",
                appIcon: NSApplication.shared.applicationIconImage ?? NSImage(),
                scale: 1.3
            )
        }
        .padding()
    }
    
}
