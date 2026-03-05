import Foundation

enum DemoProfileSnapshot {
    static let cvText = """
    Demo CV
    Maria Andersson
    Team Lead, Operations

    Summary
    Experienced team leader with a background in customer success, operations, and service quality.

    Experience
    - Team Lead, Customer Success (3 years)
    - Operations Coordinator (2 years)
    - Service Supervisor (2 years)

    Skills
    Leadership, process improvement, stakeholder management, reporting, training
    """

    static let draft: ProfileDraft = {
        var draft = ProfileDraft()
        draft.name = "Maria Andersson"
        draft.municipality = "Stockholm"
        draft.employmentType = "any"
        draft.skillsText = "Leadership, process improvement, stakeholder management, reporting, training"
        draft.cvText = cvText
        return draft
    }()

    static let aiResult = ProfileAIResult(
        keywords: ["leadership", "customer success", "operations", "quality"],
        roles: ["team lead", "operations coordinator"],
        inferredRoles: ["service manager", "quality coordinator"],
        seniority: "mid",
        locations: ["Stockholm", "Gothenburg"],
        summary: "Experienced leader focused on customer success and operational excellence.",
        occupationIds: []
    )

    static var matchPayload: ProfileMatchPayload {
        ProfileMatchPayload.build(from: draft, aiResult: aiResult)
    }

    static func matches(_ state: ProfileLocalState) -> Bool {
        state.draft.cvText == cvText
    }
}
