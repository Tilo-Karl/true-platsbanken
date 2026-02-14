import Foundation

struct JobFilterQuery {
    let occupationFieldId: String?
    let occupationIds: [String]
    let municipalityIds: [String]
    let employmentTypeId: String?
    let workingHoursTypeId: String?
}

enum JobFilterQueryMapper {
    static func map(_ filters: JobFilterState) -> JobFilterQuery {
        let occupationFieldId = filters.occupationField?.id
        let occupationIds = occupationFieldId == nil ? filters.occupations.map(\.id) : []
        let municipalityIds = filters.municipalities.map(\.id)
        let employmentTypeId = filters.employmentType?.id
        let workingHoursTypeId = filters.workingHoursType?.id

        return JobFilterQuery(
            occupationFieldId: occupationFieldId,
            occupationIds: occupationIds,
            municipalityIds: municipalityIds,
            employmentTypeId: employmentTypeId,
            workingHoursTypeId: workingHoursTypeId
        )
    }
}
