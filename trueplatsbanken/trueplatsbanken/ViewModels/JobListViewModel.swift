import Foundation

@MainActor
final class JobListViewModel: ObservableObject {
    @Published private(set) var jobs: [Job] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let jobReader: JobReading

    init(jobReader: JobReading) {
        self.jobReader = jobReader
    }

    func loadJobs() async {
        isLoading = true
        errorMessage = nil

        do {
            jobs = try await jobReader.fetchJobs()
        } catch {
            errorMessage = error.localizedDescription
            jobs = []
        }

        isLoading = false
    }
}
