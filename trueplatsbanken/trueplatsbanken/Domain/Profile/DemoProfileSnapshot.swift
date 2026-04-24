import Foundation

enum DemoProfileSnapshot {
    static let cvText = """
    Johan Bergstrom
    Product Owner · iOS Developer · Customer Success Lead

    Summary
    Product leader with a hands-on mobile background and experience building scalable support operations.

    Experience
    - Product Owner, Fintech Platform (3 years)
    - iOS Developer, Consumer Apps (4 years)
    - Customer Success Lead, B2B SaaS (2 years)

    Skills
    Product strategy, iOS/Swift, agile delivery, stakeholder management, support operations, analytics
    """

    static let draft: ProfileDraft = {
        var draft = ProfileDraft()
        draft.name = "Johan Bergstrom"
        draft.municipality = "Stockholm"
        draft.employmentType = "any"
        draft.skillsText = "Product strategy, iOS/Swift, agile delivery, stakeholder management, support operations, analytics"
        draft.cvText = cvText
        return draft
    }()

    static let aiResult = ProfileAIResult(
        keywords: ["product owner", "ios", "swift", "customer success", "agile", "support operations"],
        roles: ["product owner", "ios developer", "customer success lead"],
        inferredRoles: ["scrum master", "technical project manager", "mobile lead"],
        seniority: "senior",
        locations: ["Stockholm", "Gothenburg"],
        summary: "Product leader with mobile experience and a track record in customer success.",
        occupationIds: []
    )

    static var matchPayload: ProfileMatchPayload {
        ProfileMatchPayload.build(from: draft, aiResult: aiResult)
    }

    static func matches(_ state: ProfileLocalState) -> Bool {
        state.draft.cvText == cvText
    }
}
