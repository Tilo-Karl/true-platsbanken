import Foundation

struct JobPage {
    let jobs: [Job]
    let nextCursor: String?
}

protocol JobReading {
    func fetchJobs(filters: JobFilterState?, query: String?, cursor: String?) async throws -> JobPage
}
