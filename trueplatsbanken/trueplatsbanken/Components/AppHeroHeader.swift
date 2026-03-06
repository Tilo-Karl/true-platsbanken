import SwiftUI
import UIKit

struct AppHeroHeader<Content: View>: View {
    enum BackgroundStyle {
        case image(String)
        case gradient(LinearGradient)
    }

    let title: String
    let heroHeight: CGFloat
    let backgroundStyle: BackgroundStyle
    let trailingAction: AnyView?
    let topScrim: LinearGradient?
    private let content: Content

    init(
        title: String,
        heroHeight: CGFloat,
        showImage: Bool,
        imageName: String? = nil,
        trailingAction: AnyView? = nil,
        topScrim: LinearGradient? = nil,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.heroHeight = heroHeight
        self.trailingAction = trailingAction
        self.topScrim = topScrim
        if showImage, let imageName {
            self.backgroundStyle = .image(imageName)
        } else {
            self.backgroundStyle = .gradient(
                LinearGradient(
                    colors: [AppColors.brandBlueDark, AppColors.brandBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // The background layer - must ignore safe area to fill the notch
            backgroundView
                .ignoresSafeArea(edges: .top)
            
            if let topScrim {
                topScrim
                    .ignoresSafeArea(edges: .top)
            }
            
            // The content layer - uses safe area to avoid the notch
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if !title.isEmpty {
                        Text(title)
                            .font(AppFonts.title)
                            .foregroundStyle(AppColors.brandWhite)
                    }
                    Spacer()
                    if let trailingAction {
                        trailingAction
                    }
                }
                content
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            // We only pad the content, not the container
            .padding(.top, safeAreaTopInset + 10)
            .padding(.bottom, AppSpacing.cardGap)
        }
        .frame(height: heroHeight)
    }

    private var safeAreaTopInset: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first?.safeAreaInsets.top ?? 0
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch backgroundStyle {
        case .image(let name):
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: heroHeight)
                .clipped()
        case .gradient(let gradient):
            gradient
                .frame(maxWidth: .infinity, maxHeight: heroHeight)
        }
    }
}