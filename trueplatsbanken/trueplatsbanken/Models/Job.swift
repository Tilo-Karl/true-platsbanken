import Foundation

struct Job: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let description: String
    let employerName: String
    let employerWorkplace: String?
    let municipality: String
    let employmentType: String
    let employmentTypeLabel: String?
    let workingHoursTypeLabel: String?
    let durationLabel: String?
    let scopeOfWorkLabel: String?
    let scopeOfWork: ScopeOfWork?
    let salaryDescription: String?
    let conditions: String?
    let applicationDetailsUrl: URL?
    let logoUrl: URL?
    let lastPublicationDate: String?
    let applicationDeadline: String?
    let numberOfVacancies: Double?
    let occupationLabel: String?
    let occupationGroupLabel: String?
    let occupationFieldLabel: String?
    let publishedDisplayText: String?
    let publishedBadgeText: String?
    let publishedDateLabel: String?
    let publishedAt: Date?
    let url: URL?
}

struct ScopeOfWork: Hashable, Codable {
    let min: Double?
    let max: Double?
    let label: String?
}
