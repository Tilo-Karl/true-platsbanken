import SwiftUI

struct MatchFailureView: View {
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            AppColors.brandWhite
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(AppStrings.failureTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                Text(AppStrings.failureBody)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(AppStrings.failureRetry) {
                    onRetry()
                }
                .font(.headline)
                .foregroundStyle(AppColors.brandWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColors.brandBlueDark)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 8)
            }
            .padding(24)
        }
    }
}
