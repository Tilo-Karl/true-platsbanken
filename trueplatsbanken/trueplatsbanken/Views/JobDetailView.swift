import SwiftUI

struct JobDetailView: View {
    let job: Job
    @EnvironmentObject private var languageStore: AppLanguageStore
    
    private let heroImageName = "CVMatch11"
    private let heroHeight: CGFloat = 180
    private let headerOverlapFraction: CGFloat = 1.0 / 3.0

    var body: some View {
        let _ = languageStore.language

        HeroListScreen(
            heroImageName: heroImageName,
            heroHeight: heroHeight,
            topScrim: heroScrim,
            overlapFraction: headerOverlapFraction,
            bottomSpacing: AppSpacing.sectionGap,
            onRefresh: nil
        ) {
            HeaderSummaryCard(
                title: job.title,
                subtitle: JobPresentation.employerLine(for: job)
            ) {
                if !job.municipality.isEmpty {
                    Text(job.municipality)
                        .font(AppFonts.meta)
                        .foregroundStyle(AppColors.brandBlack.opacity(0.6))
                }
            }
        } content: {
            detailsCard
            descriptionCard
        }
        .toolbarBackground(.clear, for: .navigationBar)
        .customBackButton(
            color: heroImageName == "CVMatch12" ? AppColors.brandBlueDark : AppColors.brandAccent,
            label: AppStrings.back
        )
    }
    
    private var detailsCard: some View {
        SectionCard(title: AppStrings.jobDetailTitle) {
            VStack(alignment: .leading, spacing: AppSpacing.cardGap / 2) {
                Label(JobPresentation.employmentTypeLabel(for: job), systemImage: "clock")
                    .font(AppFonts.meta)
                if let occupation = job.occupationLabel, !occupation.isEmpty {
                    Label(occupation, systemImage: "person.text.rectangle")
                        .font(AppFonts.meta)
                }
                if let duration = job.durationLabel, !duration.isEmpty {
                    Label(duration, systemImage: "calendar.badge.clock")
                        .font(AppFonts.meta)
                }
                if let scopeLabel = JobPresentation.scopeOfWorkLabel(for: job) {
                    Label(scopeLabel, systemImage: "chart.bar")
                        .font(AppFonts.meta)
                }
                if let vacanciesLabel = JobPresentation.vacanciesLabel(for: job) {
                    Label(vacanciesLabel, systemImage: "person.3")
                        .font(AppFonts.meta)
                }
                if let deadline = JobPresentation.applicationDeadlineLabel(for: job) {
                    Label(deadline, systemImage: "calendar.badge.exclamationmark")
                        .font(AppFonts.meta)
                }
                if let publishedDateLabel = JobPresentation.publishedDateLabel(for: job) {
                    Label(publishedDateLabel, systemImage: "calendar")
                        .font(AppFonts.meta)
                }
                if let url = job.url {
                    Link(AppStrings.viewListing, destination: url)
                        .font(AppFonts.meta.weight(.semibold))
                        .foregroundStyle(AppColors.brandBlueDark)
                }
            }
        }
    }
    
    private var descriptionCard: some View {
        SectionCard(title: AppStrings.jobDescriptionTitle) {
            Text(job.description)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.brandBlack.opacity(0.85))
        }
    }
    
    private var heroScrim: LinearGradient {
        LinearGradient(
            colors: [AppColors.brandBlueDark.opacity(0.7), AppColors.brandBlueDark.opacity(0.2), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
