import SwiftUI

struct JobDetailView: View {
    let job: Job
    @EnvironmentObject private var languageStore: AppLanguageStore

    var body: some View {
        let _ = languageStore.language

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(job.title)
                        .font(.title2)
                        .bold()
                    Text(JobPresentation.employerLine(for: job))
                        .font(.headline)
                    Text(job.municipality)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Label(JobPresentation.employmentTypeLabel(for: job), systemImage: "clock")
                        .font(.subheadline)
                    if let occupation = job.occupationLabel, !occupation.isEmpty {
                        Label(occupation, systemImage: "person.text.rectangle")
                            .font(.subheadline)
                    }
                    if let duration = job.durationLabel, !duration.isEmpty {
                        Label(duration, systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                    }
                    if let scopeLabel = JobPresentation.scopeOfWorkLabel(for: job) {
                        Label(scopeLabel, systemImage: "chart.bar")
                            .font(.subheadline)
                    }
                    if let vacanciesLabel = JobPresentation.vacanciesLabel(for: job) {
                        Label(vacanciesLabel, systemImage: "person.3")
                            .font(.subheadline)
                    }
                    if let deadline = JobPresentation.applicationDeadlineLabel(for: job) {
                        Label(deadline, systemImage: "calendar.badge.exclamationmark")
                            .font(.subheadline)
                    }
                    if let publishedDateLabel = JobPresentation.publishedDateLabel(for: job) {
                        Label(publishedDateLabel, systemImage: "calendar")
                            .font(.subheadline)
                    }
                    if let url = job.url {
                        Link(AppStrings.viewListing, destination: url)
                            .font(.subheadline)
                    }
                }

                Divider()

                Text(job.description)
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle(AppStrings.jobDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
