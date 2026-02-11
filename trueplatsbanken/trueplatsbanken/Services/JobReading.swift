import Foundation

protocol JobReading {
    func fetchJobs(filters: JobFilterState?) async throws -> [Job]
}
