import Foundation

struct JobFilterState: Codable, Hashable {
    var occupationField: TaxonomyItem?
    var occupations: [TaxonomyItem]
    var municipalities: [TaxonomyItem]
    var employmentType: TaxonomyItem?
    var workingHoursType: TaxonomyItem?

    static var empty: JobFilterState {
        JobFilterState()
    }

    var isEmpty: Bool {
        occupationField == nil &&
        occupations.isEmpty &&
        municipalities.isEmpty &&
        employmentType == nil &&
        workingHoursType == nil
    }

    init(
        occupationField: TaxonomyItem? = nil,
        occupations: [TaxonomyItem] = [],
        municipalities: [TaxonomyItem] = [],
        employmentType: TaxonomyItem? = nil,
        workingHoursType: TaxonomyItem? = nil
    ) {
        self.occupationField = occupationField
        self.occupations = occupations
        self.municipalities = municipalities
        self.employmentType = employmentType
        self.workingHoursType = workingHoursType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        occupationField = try container.decodeIfPresent(TaxonomyItem.self, forKey: .occupationField)
        occupations = try container.decodeIfPresent([TaxonomyItem].self, forKey: .occupations) ?? []
        if occupations.isEmpty, let single = try container.decodeIfPresent(TaxonomyItem.self, forKey: .occupation) {
            occupations = [single]
        }
        municipalities = try container.decodeIfPresent([TaxonomyItem].self, forKey: .municipalities) ?? []
        if municipalities.isEmpty, let single = try container.decodeIfPresent(TaxonomyItem.self, forKey: .municipality) {
            municipalities = [single]
        }
        employmentType = try container.decodeIfPresent(TaxonomyItem.self, forKey: .employmentType)
        workingHoursType = try container.decodeIfPresent(TaxonomyItem.self, forKey: .workingHoursType)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(occupationField, forKey: .occupationField)
        if !occupations.isEmpty {
            try container.encode(occupations, forKey: .occupations)
        }
        if !municipalities.isEmpty {
            try container.encode(municipalities, forKey: .municipalities)
        }
        try container.encodeIfPresent(employmentType, forKey: .employmentType)
        try container.encodeIfPresent(workingHoursType, forKey: .workingHoursType)
    }

    private enum CodingKeys: String, CodingKey {
        case occupationField
        case occupations
        case occupation
        case municipalities
        case municipality
        case employmentType
        case workingHoursType
    }
}
