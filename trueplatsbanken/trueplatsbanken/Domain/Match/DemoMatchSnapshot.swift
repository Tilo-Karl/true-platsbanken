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
          "score": 0.93,
          "reasons": ["Leadership", "Customer focus", "Process improvement"],
          "job": {
            "id": "demo-job-001",
            "title": "Team Lead, Customer Success",
            "description": "Lead a team focused on customer onboarding, retention, and quality improvements.",
            "employerName": "Nordic Care AB",
            "employerWorkplace": "Gothenburg",
            "municipality": "Gothenburg",
            "employmentType": "Permanent"
          }
        },
        {
          "id": "demo-match-002",
          "score": 0.89,
          "reasons": ["Project planning", "Stakeholder management", "Operations"],
          "job": {
            "id": "demo-job-002",
            "title": "Operations Coordinator",
            "description": "Coordinate daily operations and support cross-functional teams.",
            "employerName": "Sundberg Logistics",
            "employerWorkplace": "Stockholm",
            "municipality": "Stockholm",
            "employmentType": "Permanent"
          }
        },
        {
          "id": "demo-match-003",
          "score": 0.86,
          "reasons": ["Scheduling", "People management", "Service quality"],
          "job": {
            "id": "demo-job-003",
            "title": "Shift Supervisor",
            "description": "Manage staffing schedules and ensure a consistent guest experience.",
            "employerName": "City Hotels Group",
            "employerWorkplace": "Malmo",
            "municipality": "Malmo",
            "employmentType": "Permanent"
          }
        },
        {
          "id": "demo-match-004",
          "score": 0.82,
          "reasons": ["Training", "Customer service", "Process ownership"],
          "job": {
            "id": "demo-job-004",
            "title": "Service Manager",
            "description": "Own service KPIs and coach teams to improve performance.",
            "employerName": "True Retail Nordic",
            "employerWorkplace": "Uppsala",
            "municipality": "Uppsala",
            "employmentType": "Permanent"
          }
        },
        {
          "id": "demo-match-005",
          "score": 0.79,
          "reasons": ["Quality assurance", "Communication", "Continuous improvement"],
          "job": {
            "id": "demo-job-005",
            "title": "Quality Coordinator",
            "description": "Support audits and improve quality routines across sites.",
            "employerName": "Bergstrom Health",
            "employerWorkplace": "Vasteras",
            "municipality": "Vasteras",
            "employmentType": "Permanent"
          }
        },
        {
          "id": "demo-match-006",
          "score": 0.77,
          "reasons": ["Process analysis", "Team collaboration", "Reporting"],
          "job": {
            "id": "demo-job-006",
            "title": "Business Support Specialist",
            "description": "Deliver operational reporting and support process improvements.",
            "employerName": "Svea Finance",
            "employerWorkplace": "Linkoping",
            "municipality": "Linkoping",
            "employmentType": "Permanent"
          }
        }
      ]
    }
    """
}
