import SwiftUI
import UIKit

struct StretchyHeaderContainer<HeaderContent: View>: View {
    let heroImageName: String
    let heroHeight: CGFloat
    let topScrim: LinearGradient?
    @ViewBuilder let headerOverlay: () -> HeaderContent

    var body: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("SCROLL")).minY
            // Only stretch when pulling down.
            let baseHeight = heroHeight + (minY > 0 ? minY : 0)
            // Add the notch height so the image truly fills the safe area.
            let safeTop = safeAreaTopInset
            let imageHeight = baseHeight + safeTop

            ZStack(alignment: .bottomLeading) {
                Image(heroImageName)
                    .resizable()
                    .scaledToFill()
                    // Increase height to cover the notch area.
                    .frame(width: proxy.size.width, height: imageHeight)
                    // Pin the image to the top edge (including the notch).
                    .offset(y: (minY > 0 ? -minY : 0) - safeTop)
                    .clipped()

                if let topScrim {
                    topScrim
                        // Scrim follows the visible hero area (not the extra notch height).
                        .frame(width: proxy.size.width, height: baseHeight)
                        .offset(y: minY > 0 ? -minY : 0)
                }

                headerOverlay()
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, 20)
                    .offset(y: minY > 0 ? -minY : 0)
            }
        }
        .frame(height: heroHeight)
        // CRITICAL: This allows the container's internal coordinate 0 to be the screen top
        .ignoresSafeArea(edges: .top) 
    }

    private var safeAreaTopInset: CGFloat {
        // Use the key window safe-area inset to measure the notch height.
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window?.safeAreaInsets.top ?? 0
    }
}
