import SwiftUI

struct MatchProcessingView: View {
    let entitlementMessage: String?

    var body: some View {
        ZStack {
            AppColors.brandWhite
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text(AppStrings.processingTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(AppStrings.processingSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let entitlementMessage {
                    VStack(spacing: 4) {
                        Text(AppStrings.processingIncludedTitle)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppColors.brandBlueDark)
                        Text(entitlementMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(24)
        }
    }
}
