import Foundation

struct ProfileBuilder {
    static func buildProfile(from draft: ProfileDraft) -> Profile {
        let skills = draft.skillsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Profile(
            id: draft.userId,
            userId: draft.userId,
            name: draft.name,
            email: draft.email,
            phone: draft.phone,
            municipality: draft.municipality,
            employmentType: draft.employmentType,
            skills: skills,
            cvText: draft.cvText
        )
    }
}
