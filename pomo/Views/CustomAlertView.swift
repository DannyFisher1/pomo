import SwiftUI

struct CustomAlertView: View {
    let title: String
    let message: String
    let appIcon: NSImage
    let scale: Double

    // Base sizes for scaling
    var baseIconSize: CGFloat = 40
    var baseTitleSize: CGFloat = 13
    var baseMessageSize: CGFloat = 11
    var baseHSpacing: CGFloat = 6
    var baseVSpacing: CGFloat = 0
    var basePadding: CGFloat = 10
    var cornerRadius: CGFloat = 12

    var body: some View {
        HStack(alignment: .center, spacing: baseHSpacing * scale) {
            Image(nsImage: appIcon)
                .resizable()
                .scaledToFit()
                .frame(width: baseIconSize * scale, height: baseIconSize * scale)
                .padding(.leading, basePadding * scale)

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
        .padding(.trailing, basePadding * scale)
        .frame(maxWidth: 350 * scale, minHeight: 70 * scale)
        .background(
            .ultraThickMaterial,
            in: RoundedRectangle(cornerRadius: cornerRadius * scale, style: .continuous)
        )
        .shadow(color: .black.opacity(0.2), radius: 5 * scale, y: 3 * scale)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
