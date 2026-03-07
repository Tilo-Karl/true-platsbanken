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
            let safeTop = safeAreaTopInset
            
            // This is your Master Math from Profile View
            let baseHeight = heroHeight + (minY > 0 ? minY : 0)
            let imageHeight = baseHeight + safeTop
            let imageOffset = (minY > 0 ? -minY : 0) - safeTop

            // We use alignment .bottom so the image "grows" upwards into the notch
            ZStack(alignment: .bottomLeading) {
                // 1. BACKGROUND IMAGE
                Image(heroImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: imageHeight)
                    // This offset pushes it into the notch area
                    .offset(y: imageOffset) 

                // 2. SCRIM (Matches image offset exactly)
                if let topScrim {
                    topScrim
                        .frame(width: proxy.size.width, height: imageHeight)
                        .offset(y: imageOffset)
                }

                // 3. OVERLAY CONTENT
                headerOverlay()
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, 20)
                    .offset(y: minY > 0 ? -minY : 0)
            }
        }
        .frame(height: heroHeight)
        // CRITICAL: This allows the image offset to actually enter the notch area
        .ignoresSafeArea(edges: .top) 
    }

    private var safeAreaTopInset: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }
        return window?.safeAreaInsets.top ?? 0
    }
}