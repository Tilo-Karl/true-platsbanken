import SwiftUI

struct MatchProcessingView: View {
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
            }
            .padding(24)
        }
    }
}
