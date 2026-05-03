import Foundation

struct ProfileEducationPath: Hashable, Codable {
    let strengthen: [ProfileEducationPathItem]
    let pivot: [ProfileEducationPathItem]

    static let empty = ProfileEducationPath(strengthen: [], pivot: [])

    var hasAnyItems: Bool {
        !strengthen.isEmpty || !pivot.isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case strengthen
        case pivot
    }

    init(
        strengthen: [ProfileEducationPathItem],
        pivot: [ProfileEducationPathItem]
    ) {
        self.strengthen = strengthen
        self.pivot = pivot
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        strengthen = try container.decodeIfPresent([ProfileEducationPathItem].self, forKey: .strengthen) ?? []
        pivot = try container.decodeIfPresent([ProfileEducationPathItem].self, forKey: .pivot) ?? []
    }
}

struct ProfileEducationPathItem: Hashable, Codable, Identifiable {
    let track: String
    let occupationId: String
    let occupationLabel: String
    let courseTitle: String
    let courseId: String?
    let courseUrl: String?
    let provider: String?
    let startDate: String?
    let duration: String?
    let confidence: Double
    let reason: String
    let sourceSignals: [String]

    var id: String {
        [
            track,
            courseId ?? "",
            occupationId,
            courseTitle,
            provider ?? "",
            startDate ?? ""
        ].joined(separator: "::")
    }

    private enum CodingKeys: String, CodingKey {
        case track
        case occupationId
        case occupationLabel
        case courseTitle
        case courseId
        case courseUrl
        case provider
        case startDate
        case duration
        case confidence
        case reason
        case sourceSignals
    }

    init(
        track: String,
        occupationId: String,
        occupationLabel: String,
        courseTitle: String,
        courseId: String?,
        courseUrl: String?,
        provider: String?,
        startDate: String?,
        duration: String?,
        confidence: Double,
        reason: String,
        sourceSignals: [String]
    ) {
        self.track = track
        self.occupationId = occupationId
        self.occupationLabel = occupationLabel
        self.courseTitle = courseTitle
        self.courseId = courseId
        self.courseUrl = courseUrl
        self.provider = provider
        self.startDate = startDate
        self.duration = duration
        self.confidence = confidence
        self.reason = reason
        self.sourceSignals = sourceSignals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        track = try container.decodeIfPresent(String.self, forKey: .track) ?? ""
        occupationId = try container.decodeIfPresent(String.self, forKey: .occupationId) ?? ""
        occupationLabel = try container.decodeIfPresent(String.self, forKey: .occupationLabel) ?? ""
        courseTitle = try container.decodeIfPresent(String.self, forKey: .courseTitle) ?? ""
        courseId = try container.decodeIfPresent(String.self, forKey: .courseId)
        courseUrl = try container.decodeIfPresent(String.self, forKey: .courseUrl)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        duration = try container.decodeIfPresent(String.self, forKey: .duration)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
        reason = try container.decodeIfPresent(String.self, forKey: .reason) ?? ""
        sourceSignals = try container.decodeIfPresent([String].self, forKey: .sourceSignals) ?? []
    }
}
