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
                    .font(AppFonts.meta.weight(.semibold))
                    .foregroundStyle(isEmphasized ? AppColors.brandAccent : AppColors.brandWhite.opacity(0.9))
                if !value.isEmpty {
                    Text(value)
                        .font(AppFonts.meta)
                        .foregroundStyle(isEmphasized ? AppColors.brandAccent : AppColors.brandWhite)
                }
            }
            .padding(.horizontal, AppSpacing.cardGap)
            .padding(.vertical, AppSpacing.cardGap / 2)
            .background(AppColors.brandBlue.opacity(0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppColors.brandAccent.opacity(0.6), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
