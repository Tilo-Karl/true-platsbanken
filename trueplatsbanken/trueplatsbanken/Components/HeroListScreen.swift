import SwiftUI

struct HeroListScreen<HeaderCard: View, Content: View>: View {
    let heroImageName: String
    let heroHeight: CGFloat
    let topScrim: LinearGradient?
    let overlapFraction: CGFloat
    let bottomSpacing: CGFloat
    let onRefresh: (() async -> Void)?
    @ViewBuilder let headerCard: () -> HeaderCard
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 0) {
                    HeroOverlapHeader(
                        heroImageName: heroImageName,
                        heroHeight: heroHeight,
                        topScrim: topScrim,
                        overlapFraction: overlapFraction,
                        bottomSpacing: bottomSpacing
                    ) {
                        headerCard()
                    }

                    LazyVStack(spacing: AppSpacing.cardGap) {
                        content()
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, AppSpacing.sectionGap)
                }
            }
            .coordinateSpace(name: "SCROLL")
            .ignoresSafeArea(edges: .top)
            .refreshable {
                if let onRefresh {
                    await onRefresh()
                }
            }
        }
    }
}
