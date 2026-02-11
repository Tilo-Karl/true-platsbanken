import SwiftUI

struct JobFilterChip: View {
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(AppColors.brandWhite.opacity(0.9))
                Text(value)
                    .font(.caption)
                    .foregroundStyle(AppColors.brandWhite)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.brandBlue.opacity(0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppColors.brandGreen.opacity(0.6), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
