import Foundation

struct ProfileMatchPayload: Hashable, Codable {
    let keywords: [String]
    let roles: [String]
    let inferredRoles: [String]
    let occupationIds: [String]
    let seniority: String?
    let locations: [String]
    let summary: String
    let municipality: String
    let employmentType: String
    let skills: [String]
    let cvText: String

    static func build(from draft: ProfileDraft, aiResult: ProfileAIResult) -> ProfileMatchPayload {
        return ProfileMatchPayload(
            keywords: aiResult.keywords,
            roles: aiResult.roles,
            inferredRoles: aiResult.inferredRoles,
            occupationIds: aiResult.occupationIds,
            seniority: aiResult.seniority,
            locations: aiResult.locations,
            summary: aiResult.summary,
            municipality: draft.municipality,
            employmentType: draft.employmentType,
            skills: splitSkills(from: draft.skillsText),
            cvText: draft.cvText
        )
    }

    private static func splitSkills(from text: String) -> [String] {
        return text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

}
