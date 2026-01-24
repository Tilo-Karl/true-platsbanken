import SwiftUI

struct JobListRow: View {
    let job: Job
    @EnvironmentObject private var languageStore: AppLanguageStore

    var body: some View {
        let _ = languageStore.language

        VStack(alignment: .leading, spacing: 4) {
            Text(headlineText())
                .font(.headline)

            Text(employerLine())
                .font(.subheadline)

            if let occupation = nonEmpty(job.occupationLabel) {
                Text(occupation)
                    .font(.subheadline)
            }

            if let publishedText = job.publishedDisplayText {
                HStack(spacing: 8) {
                    if let badgeText = job.publishedBadgeText {
                        Text(badgeText)
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.25))
                            .clipShape(Capsule())
                    }

                    Text(publishedText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func headlineText() -> String {
        if let vacancies = job.numberOfVacancies {
            let count = Int(vacancies)
            if count > 1 {
                return AppStrings.headlineWithVacancies(job.title, count)
            }
        }
        return job.title
    }

    private func employerLine() -> String {
        if let workplace = nonEmpty(job.employerWorkplace) {
            return workplaceLine(workplace)
        }
        return workplaceLine(job.employerName)
    }

    private func workplaceLine(_ workplace: String) -> String {
        let municipality = job.municipality.trimmingCharacters(in: .whitespacesAndNewlines)
        if municipality.isEmpty {
            return workplace
        }
        return AppStrings.employerLine(workplace: workplace, municipality: municipality)
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return value
    }
}
