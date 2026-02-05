import Foundation

struct TaxonomySnapshot: Codable, Hashable {
    let language: String
    let fetchedAt: Date
    let occupationFields: [TaxonomyItem]
    let occupationGroups: [TaxonomyItem]
    let occupations: [TaxonomyItem]
    let regions: [TaxonomyItem]
    let municipalities: [TaxonomyItem]
    let employmentTypes: [TaxonomyItem]
    let workingHoursTypes: [TaxonomyItem]
}
