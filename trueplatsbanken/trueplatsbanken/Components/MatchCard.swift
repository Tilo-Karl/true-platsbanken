import SwiftUI

struct MatchCard: View {
    let match: MatchResult

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.cardGap / 2) {
                Text(JobPresentation.headline(for: match.job))
                    .font(AppFonts.cardTitle)
                    .foregroundStyle(AppColors.brandBlueDark)

                Text(JobPresentation.employerLine(for: match.job))
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.brandBlack.opacity(0.8))

                if let occupation = JobPresentation.occupationLabel(for: match.job) {
                    Text(occupation)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.brandBlack.opacity(0.7))
                }

                if let published = JobPresentation.publishedPresentation(for: match.job, now: Date()) {
                    HStack(spacing: AppSpacing.cardGap) {
                        if match.isNewToday == true {
                            Text(AppStrings.matchesNewToday)
                                .font(AppFonts.meta.weight(.semibold))
                                .padding(.horizontal, AppSpacing.cardGap)
                                .padding(.vertical, AppSpacing.cardGap / 3)
                                .background(AppColors.brandAccent.opacity(0.25))
                                .clipShape(Capsule())
                        }

                        if let badgeText = published.badgeLabel {
                            Text(badgeText)
                                .font(AppFonts.meta.weight(.semibold))
                                .padding(.horizontal, AppSpacing.cardGap)
                                .padding(.vertical, AppSpacing.cardGap / 3)
                                .background(AppColors.brandAccent.opacity(0.25))
                                .clipShape(Capsule())
                        }
                        Text(published.listLabel)
                            .font(AppFonts.meta)
                            .foregroundStyle(AppColors.brandBlack.opacity(0.6))
                    }
                } else if match.isNewToday == true {
                    Text(AppStrings.matchesNewToday)
                        .font(AppFonts.meta.weight(.semibold))
                        .padding(.horizontal, AppSpacing.cardGap)
                        .padding(.vertical, AppSpacing.cardGap / 3)
                        .background(AppColors.brandAccent.opacity(0.25))
                        .clipShape(Capsule())
                }

                if let score = match.score {
                    MatchBadge(score: score)
                }
            }
        }
    }
}
