import Foundation

struct DemoMatchSnapshot: Decodable {
    let matches: [MatchResult]

    static func load() throws -> [MatchResult] {
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        return try decoder.decode(DemoMatchSnapshot.self, from: data).matches
    }

    private static let json = """
    {
      "matches": [
        {
          "id": "demo-match-001",
          "score": 0.92,
          "reasons": ["Product strategy", "Stakeholder alignment", "Agile delivery"],
          "job": {
            "id": "demo-job-001",
            "title": "Product Owner",
            "description": "Own roadmap priorities and lead discovery for a customer-facing platform.",
            "employerName": "Nordic Fintech AB",
            "employerWorkplace": "Gothenburg",
            "municipality": "Gothenburg",
            "employmentType": "Permanent"
          }
        },
        {
          "id": "demo-match-002",
          "score": 0.88,
          "reasons": ["iOS", "Swift", "Mobile product"],
          "job": {
            "id": "demo-job-002",
            "title": "iOS Developer",
            "description": "Build and iterate consumer mobile experiences in Swift.",
            "employerName": "Appline Studio",
            "employerWorkplace": "Stockholm",
            "municipality": "Stockholm",
            "employmentType": "Permanent"
          }
        },
        {
          "id": "demo-match-003",
          "score": 0.85,
          "reasons": ["Agile leadership", "Team facilitation", "Delivery coaching"],
          "job": {
            "id": "demo-job-003",
            "title": "Scrum Master",
            "description": "Coach cross-functional teams and remove delivery blockers.",
            "employerName": "Flow Systems",
            "employerWorkplace": "Malmo",
            "municipality": "Malmo",
            "employmentType": "Permanent"
          }
        },
        {
          "id": "demo-match-004",
          "score": 0.83,
          "reasons": ["Customer success", "Retention", "Process improvement"],
          "job": {
            "id": "demo-job-004",
            "title": "Customer Success Lead",
            "description": "Lead onboarding and customer expansion initiatives for B2B SaaS.",
            "employerName": "Bright SaaS",
            "employerWorkplace": "Uppsala",
            "municipality": "Uppsala",
            "employmentType": "Permanent"
          }
        },
        {
          "id": "demo-match-005",
          "score": 0.80,
          "reasons": ["Technical leadership", "Mobile architecture", "Mentorship"],
          "job": {
            "id": "demo-job-005",
            "title": "Mobile Lead",
            "description": "Guide mobile engineering direction and support team delivery.",
            "employerName": "Northwind Mobile",
            "employerWorkplace": "Vasteras",
            "municipality": "Vasteras",
            "employmentType": "Permanent"
          }
        },
        {
          "id": "demo-match-006",
          "score": 0.78,
          "reasons": ["Project delivery", "Cross-team alignment", "Product execution"],
          "job": {
            "id": "demo-job-006",
            "title": "Technical Project Manager",
            "description": "Coordinate product and engineering delivery for customer initiatives.",
            "employerName": "Svea Digital",
            "employerWorkplace": "Linkoping",
            "municipality": "Linkoping",
            "employmentType": "Permanent"
          }
        }
      ]
    }
    """
}
