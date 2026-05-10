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
        occupationIds: [],
        opportunityProfile: CandidateOpportunityProfile(
            primaryDomains: ["IT / software / product", "delivery / leadership"],
            secondaryDomains: ["customer / commercial", "people / training"],
            transferableCapabilities: [
                "leadership",
                "planning",
                "stakeholder communication",
                "technical literacy"
            ],
            workEnvironments: ["cross-functional teams", "delivery-driven", "customer-facing"],
            careerStage: "advanced",
            coreOccupationTargets: [
                CoreOccupationTarget(occupationId: "fg7B_yov_smw", occupationLabel: "Systemutvecklare/Programmerare"),
                CoreOccupationTarget(occupationId: "xJQz_S3z_vab", occupationLabel: "Agil coach/Agile coach")
            ],
            pivotOpportunityFamilies: [
                PivotOpportunityFamily(
                    id: "technical_training",
                    label: "technical training",
                    fitScore: 11,
                    evidenceScore: 4,
                    capabilityScore: 3,
                    occupationIds: ["qa2M_4S8_aPz"],
                    occupationSeeds: ["Teknisk utbildare", "Handledare"],
                    searchTerms: ["teknisk utbildare", "instruktör"]
                ),
                PivotOpportunityFamily(
                    id: "implementation_consulting",
                    label: "implementation consulting",
                    fitScore: 10,
                    evidenceScore: 3,
                    capabilityScore: 3,
                    occupationIds: ["Wopw_vxK_3FK"],
                    occupationSeeds: ["Implementationskonsult", "Verksamhetskonsult"],
                    searchTerms: ["implementationskonsult", "verksamhetskonsult"]
                ),
                PivotOpportunityFamily(
                    id: "supply_chain_purchasing",
                    label: "supply chain / purchasing",
                    fitScore: 8,
                    evidenceScore: 2,
                    capabilityScore: 2,
                    occupationIds: ["6kPj_4fA_v7H"],
                    occupationSeeds: ["Inköpare"],
                    searchTerms: ["inköpare", "operativt inköp"]
                ),
                PivotOpportunityFamily(
                    id: "logistics_coordination",
                    label: "logistics coordination",
                    fitScore: 7,
                    evidenceScore: 2,
                    capabilityScore: 2,
                    occupationIds: ["eN4r_jfL_Q9a"],
                    occupationSeeds: ["Logistikkoordinator"],
                    searchTerms: ["logistik koordinator", "transport koordinator"]
                )
            ],
            lowLeverageFamilies: ["quality / governance"]
        ),
        educationPath: ProfileEducationPath(
            strengthen: [
                ProfileEducationPathItem(
                    track: "strengthen",
                    occupationId: "xJQz_S3z_vab",
                    occupationLabel: "Agil coach/Agile coach",
                    courseTitle: "Agil projektledning",
                    courseId: "demo.strengthen.1",
                    courseUrl: "https://www.ihm.se/utbildningar/management/agil-projektledare/",
                    provider: "IHM Business School",
                    startDate: "2026-09-01",
                    duration: nil,
                    confidence: 0.86,
                    reason: "Reinforces delivery and facilitation strengths already present in your profile.",
                    sourceSignals: ["agile", "stakeholder management", "product strategy"]
                ),
                ProfileEducationPathItem(
                    track: "strengthen",
                    occupationId: "fg7B_yov_smw",
                    occupationLabel: "Systemutvecklare/Programmerare",
                    courseTitle: "iOS Advanced Architecture",
                    courseId: "demo.strengthen.2",
                    courseUrl: "https://developer.apple.com/tutorials/",
                    provider: "Apple Developer",
                    startDate: "2026-10-15",
                    duration: nil,
                    confidence: 0.79,
                    reason: "Keeps your technical edge strong for senior app/product delivery roles.",
                    sourceSignals: ["ios", "swift", "technical literacy"]
                ),
                ProfileEducationPathItem(
                    track: "strengthen",
                    occupationId: "xJQz_S3z_vab",
                    occupationLabel: "Agil coach/Agile coach",
                    courseTitle: "Facilitering och förändringsledning",
                    courseId: "demo.strengthen.3",
                    courseUrl: "https://www.hyperisland.com/",
                    provider: "Hyper Island",
                    startDate: "2026-11-03",
                    duration: nil,
                    confidence: 0.75,
                    reason: "Builds stronger leadership influence in complex cross-functional settings.",
                    sourceSignals: ["leadership", "coordination", "customer success"]
                )
            ],
            pivot: [
                ProfileEducationPathItem(
                    track: "pivot",
                    occupationId: "Wopw_vxK_3FK",
                    occupationLabel: "Implementationskonsult",
                    courseTitle: "Business Process Mapping",
                    courseId: "demo.pivot.1",
                    courseUrl: "https://www.coursera.org/",
                    provider: "Coursera",
                    startDate: "2026-08-20",
                    duration: nil,
                    confidence: 0.8,
                    reason: "Supports a realistic move into implementation consulting with your delivery background.",
                    sourceSignals: ["stakeholder communication", "planning", "process"]
                ),
                ProfileEducationPathItem(
                    track: "pivot",
                    occupationId: "6kPj_4fA_v7H",
                    occupationLabel: "Inköpare",
                    courseTitle: "Operativt inköp och upphandling",
                    courseId: "demo.pivot.2",
                    courseUrl: "https://nackademin.se/",
                    provider: "Nackademin",
                    startDate: "2026-09-05",
                    duration: nil,
                    confidence: 0.73,
                    reason: "Leverages planning and vendor-facing communication for a procurement pivot.",
                    sourceSignals: ["planning", "communication", "operations"]
                ),
                ProfileEducationPathItem(
                    track: "pivot",
                    occupationId: "eN4r_jfL_Q9a",
                    occupationLabel: "Logistikkoordinator",
                    courseTitle: "Logistik och flödesoptimering",
                    courseId: "demo.pivot.3",
                    courseUrl: "https://www.kyh.se/",
                    provider: "KYH",
                    startDate: "2026-10-01",
                    duration: nil,
                    confidence: 0.71,
                    reason: "Matches your systems perspective and coordination capability in operational environments.",
                    sourceSignals: ["systems thinking", "coordination", "delivery"]
                )
            ]
        )
    )

    static var matchPayload: ProfileMatchPayload {
        ProfileMatchPayload.build(from: draft, aiResult: aiResult)
    }

    static func matches(_ state: ProfileLocalState) -> Bool {
        state.draft.cvText == cvText
    }
}
