import SwiftUI

struct JobDetailView: View {
    let job: Job

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(job.title)
                        .font(.title2)
                        .bold()
                    Text(employerLine())
                        .font(.headline)
                    Text(job.municipality)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    if let label = job.employmentTypeLabel, !label.isEmpty {
                        Label(label, systemImage: "clock")
                            .font(.subheadline)
                    } else {
                        Label(job.employmentType.replacingOccurrences(of: "_", with: " "), systemImage: "clock")
                            .font(.subheadline)
                    }
                    if let occupation = job.occupationLabel, !occupation.isEmpty {
                        Label(occupation, systemImage: "person.text.rectangle")
                            .font(.subheadline)
                    }
                    if let duration = job.durationLabel, !duration.isEmpty {
                        Label(duration, systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                    }
                    if let scopeLabel = job.scopeOfWorkLabel, !scopeLabel.isEmpty {
                        Label(scopeLabel, systemImage: "chart.bar")
                            .font(.subheadline)
                    }
                    if let vacanciesLabel = vacanciesLabel() {
                        Label(vacanciesLabel, systemImage: "person.3")
                            .font(.subheadline)
                    }
                    if let deadline = applicationDeadlineLabel() {
                        Label(deadline, systemImage: "calendar.badge.exclamationmark")
                            .font(.subheadline)
                    }
                    if let publishedDateLabel = job.publishedDateLabel {
                        Label(publishedDateLabel, systemImage: "calendar")
                            .font(.subheadline)
                    }
                    if let url = job.url {
                        Link("View listing", destination: url)
                            .font(.subheadline)
                    }
                }

                Divider()

                Text(job.description)
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("Job Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func employerLine() -> String {
        if let workplace = job.employerWorkplace, !workplace.isEmpty {
            return workplace
        }
        return job.employerName
    }

    private func vacanciesLabel() -> String? {
        guard let vacancies = job.numberOfVacancies else {
            return nil
        }
        let count = Int(vacancies)
        if count == 0 {
            return nil
        }
        return "Antal jobb: \(count)"
    }

    private func applicationDeadlineLabel() -> String? {
        guard let value = job.applicationDeadline, !value.isEmpty else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.dateFormat = "yyyy-MM-dd"

        if let date = parseISO8601(value) {
            let base = formatter.string(from: date)
            if let days = daysUntil(date), days >= 0 {
                return "Sista ansökningsdag: \(base) (om \(days) dagar)"
            }
            return "Sista ansökningsdag: \(base)"
        }

        return "Sista ansökningsdag: \(value)"
    }

    private func daysUntil(_ date: Date) -> Int? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    private func parseISO8601(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        let fallback = ISO8601DateFormatter()
        return fallback.date(from: value)
    }
}
