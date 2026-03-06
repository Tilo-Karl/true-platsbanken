import SwiftUI

struct MatchBadge: View {
    let score: Double

    private var tint: Color {
        switch score {
        case 0.7...:
            return .green
        case 0.5..<0.7:
            return .orange
        default:
            return .red
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
            Text(AppStrings.scoreLabel(Int(score * 100)))
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.brandBlack.opacity(0.6))
        }
    }
}
