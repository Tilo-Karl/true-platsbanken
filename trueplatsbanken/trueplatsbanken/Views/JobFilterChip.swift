import SwiftUI

struct JobFilterChip: View {
    let title: String
    let value: String
    let action: () -> Void
    var isEmphasized: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(isEmphasized ? AppColors.brandGreen : AppColors.brandWhite.opacity(0.9))
                if !value.isEmpty {
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(isEmphasized ? AppColors.brandGreen : AppColors.brandWhite)
                }
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
