import SwiftUI

struct JobListRow: View {
    let job: Job
    @EnvironmentObject private var languageStore: AppLanguageStore

    var body: some View {
        let _ = languageStore.language

        VStack(alignment: .leading, spacing: 4) {
            Text(JobPresentation.headline(for: job))
                .font(.headline)

            Text(JobPresentation.employerLine(for: job))
                .font(.subheadline)

            if let occupation = JobPresentation.occupationLabel(for: job) {
                Text(occupation)
                    .font(.subheadline)
            }

            if let published = JobPresentation.publishedPresentation(for: job, now: Date()) {
                HStack(spacing: 8) {
                    if let badgeText = published.badgeLabel {
                        Text(badgeText)
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.25))
                            .clipShape(Capsule())
                    }

                    Text(published.listLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
