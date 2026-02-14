import SwiftUI

struct MatchMarketingOverlayView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AppColors.brandBlack.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(AppStrings.matchesOverlayTitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.brandBlack)
                        .multilineTextAlignment(.center)
                    Text(AppStrings.matchesOverlayBody)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: onDismiss) {
                    Text(AppStrings.matchesOverlayDismiss)
                        .font(.headline)
                        .foregroundStyle(AppColors.brandWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.brandBlueDark)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(20)
            .background(AppColors.brandWhite)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 24)
        }
    }
}
