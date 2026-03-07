import SwiftUI

struct HeaderSummaryCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let badgeText: String?
    let badgeBackground: Color
    let badgeForeground: Color
    private let hasContent: Bool
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        badgeText: String? = nil,
        badgeBackground: Color = AppColors.brandAccent.opacity(0.5),
        badgeForeground: Color = AppColors.brandWhite,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badgeText = badgeText
        self.badgeBackground = badgeBackground
        self.badgeForeground = badgeForeground
        self.hasContent = true
        self.content = content
    }

    init(
        title: String,
        subtitle: String? = nil,
        badgeText: String? = nil,
        badgeBackground: Color = AppColors.brandAccent.opacity(0.5),
        badgeForeground: Color = AppColors.brandWhite
    ) where Content == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.badgeText = badgeText
        self.badgeBackground = badgeBackground
        self.badgeForeground = badgeForeground
        self.hasContent = false
        self.content = { EmptyView() }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(AppFonts.sectionTitle)
                        .foregroundStyle(AppColors.brandBlueDark)

                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppFonts.meta)
                            .foregroundStyle(AppColors.brandBlack.opacity(0.6))
                    }
                }

                if let badgeText, !badgeText.isEmpty {
                    Text(badgeText)
                        .font(AppFonts.meta.weight(.bold))
                        .foregroundStyle(badgeForeground)
                        .padding(.vertical, AppSpacing.cardGap / 3)
                        .padding(.horizontal, AppSpacing.cardGap)
                        .background(badgeBackground)
                        .clipShape(Capsule())
                }

                if hasContent {
                    content()
                }
            }
        }
    }
}
