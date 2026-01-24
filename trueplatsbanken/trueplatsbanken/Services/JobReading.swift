import Foundation

protocol JobReading {
    func fetchJobs() async throws -> [Job]
}
