import SwiftUI

struct NavigationBackButtonModifier: ViewModifier {
    let color: Color
    let label: String?

    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            if let label, !label.isEmpty {
                                Text(label)
                            }
                        }
                        .font(AppFonts.body.weight(.bold))
                        .foregroundStyle(color)
                    }
                }
            }
    }
}

extension View {
    func customBackButton(color: Color, label: String? = nil) -> some View {
        modifier(NavigationBackButtonModifier(color: color, label: label))
    }
}
