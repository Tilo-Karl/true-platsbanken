import Foundation

protocol JobReading {
    func fetchJobs(filters: JobFilterState?, query: String?) async throws -> [Job]
}
