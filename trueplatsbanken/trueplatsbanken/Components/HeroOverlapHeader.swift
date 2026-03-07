import SwiftUI

struct HeroOverlapHeader<Card: View>: View {
    let heroImageName: String
    let heroHeight: CGFloat
    let topScrim: LinearGradient?
    let overlapFraction: CGFloat
    let bottomSpacing: CGFloat
    @ViewBuilder let card: () -> Card

    @State private var cardHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            StretchyHeaderContainer(
                heroImageName: heroImageName,
                heroHeight: heroHeight,
                topScrim: topScrim
            ) {
                EmptyView()
            }

            card()
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: HeroOverlapCardHeightKey.self, value: proxy.size.height)
                    }
                )
                .padding(.horizontal, AppSpacing.screenPadding)
                // Overlap by a fixed fraction of the card height (content-independent).
                .padding(.top, max(0, heroHeight - cardHeight * overlapFraction))
        }
        .onPreferenceChange(HeroOverlapCardHeightKey.self) { cardHeight = $0 }
        // Allow room for the lower half of the card + a small gap.
        .padding(.bottom, bottomSpacing)
    }
}

private struct HeroOverlapCardHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
