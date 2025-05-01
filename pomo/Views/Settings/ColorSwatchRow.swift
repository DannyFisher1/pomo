import SwiftUI

struct ColorSwatchRow: View {
    let label: String
    @Binding var selectedColor: Color
    let action: () -> Void // Action to perform on tap

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Rectangle()
                .fill(selectedColor)
                .frame(width: 60, height: 24)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: selectedColor.opacity(0.3), radius: 3, y: 1)
                .contentShape(Rectangle()) // Ensure the whole swatch area is tappable
                .onTapGesture {
                    action() // Trigger the provided action (e.g., show custom picker)
                }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

// Optional Preview
struct ColorSwatchRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ColorSwatchRow(label: "Pomodoro Color", selectedColor: .constant(.red)) {}
            ColorSwatchRow(label: "Short Break Color", selectedColor: .constant(.green)) {}
            ColorSwatchRow(label: "Long Break Color", selectedColor: .constant(.blue)) {}
        }
        .padding()
        .frame(width: 300)
    }
} 