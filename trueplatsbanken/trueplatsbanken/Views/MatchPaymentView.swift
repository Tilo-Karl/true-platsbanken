import SwiftUI

struct MatchPaymentView: View {
    let price: String
    let uploadSummary: String?
    let entitlementMessage: String?
    let errorMessage: String?
    let isProcessing: Bool
    let onConfirm: () async -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            AppColors.brandWhite
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(AppStrings.paymentTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                Text(AppStrings.paymentSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let entitlementMessage {
                    Text(entitlementMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }

                if let uploadSummary {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.brandGreen)
                        Text(uploadSummary)
                            .font(.footnote)
                            .foregroundStyle(AppColors.brandBlack.opacity(0.7))
                    }
                    .padding(.top, 4)
                }

                Text(price)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 8) {
                    labelRow(AppStrings.matchesOverlayBullet2)
                    labelRow(AppStrings.matchesOverlayBullet3)
                }
                .padding(.top, 8)

                if isProcessing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.85)
                        Text(AppStrings.paymentProcessing)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }

                Button {
                    Task {
                        await onConfirm()
                    }
                } label: {
                    Text(isProcessing ? AppStrings.paymentProcessing : AppStrings.paymentContinue)
                        .font(.headline)
                        .foregroundStyle(AppColors.brandWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.brandBlueDark)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.top, 12)
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.7 : 1)

                Button(AppStrings.paymentCancel) {
                    onCancel()
                }
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                .disabled(isProcessing)
            }
            .padding(24)
        }
    }

    private func labelRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(AppColors.brandBlue.opacity(0.6))
                .frame(width: 6, height: 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
