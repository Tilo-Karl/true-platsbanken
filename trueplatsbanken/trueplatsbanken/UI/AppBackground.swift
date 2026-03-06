import SwiftUI

struct AppBackground: View {
    var body: some View {
        AppColors.backgroundGradient
            .ignoresSafeArea()
    }
}

extension View {
    func appBackground() -> some View {
        background(AppColors.backgroundGradient)
            .ignoresSafeArea()
    }
}
