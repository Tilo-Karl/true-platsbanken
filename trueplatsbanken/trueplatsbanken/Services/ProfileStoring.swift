import Foundation

protocol ProfileStateReading {
    func loadState() async throws -> ProfileLocalState?
}

protocol ProfileStateWriting {
    func saveState(_ state: ProfileLocalState) async throws
}
