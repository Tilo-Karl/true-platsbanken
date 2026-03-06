import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                Text(title)
                    .font(AppFonts.sectionTitle)
                    .foregroundStyle(AppColors.brandBlueDark)
                content
            }
        }
    }
}
