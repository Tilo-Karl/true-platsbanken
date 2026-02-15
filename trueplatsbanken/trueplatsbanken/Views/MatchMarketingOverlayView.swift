import SwiftUI
import PhotosUI

struct MatchMarketingOverlayView: View {
    let imageName: String
    @Binding var selectedPhotos: [PhotosPickerItem]
    let onUploadFile: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AppColors.brandBlack.opacity(0.35)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 0) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150)
                    .clipped()

                VStack(spacing: 10) {
                    Text(AppStrings.matchesOverlayTitle)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.brandBlack.opacity(0.9))
                        .multilineTextAlignment(.center)
                    Text(AppStrings.matchesOverlaySubtitle)
                        .font(.footnote)
                        .foregroundStyle(AppColors.brandBlack.opacity(0.6))
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: 8) {
                        bullet(AppStrings.matchesOverlayBullet2)
                        bullet(AppStrings.matchesOverlayBullet3)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 2,
                        matching: .images
                    ) {
                        Text(AppStrings.matchesOverlayUploadPhoto)
                            .font(.headline)
                            .foregroundStyle(AppColors.brandWhite)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.brandBlueDark)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button(action: onUploadFile) {
                        Text(AppStrings.matchesOverlayUploadFile)
                            .font(.headline)
                            .foregroundStyle(AppColors.brandBlueDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.brandBlueDark.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                }
                .padding(.top, 12)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
            .frame(maxWidth: 290)
            .background(AppColors.brandWhite)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 24)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Circle()
                .fill(AppColors.brandBlue.opacity(0.6))
                .frame(width: 6, height: 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
