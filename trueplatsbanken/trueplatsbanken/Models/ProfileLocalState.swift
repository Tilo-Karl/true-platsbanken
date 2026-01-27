import Foundation

struct ProfileLocalState: Hashable, Codable {
    let draft: ProfileDraft
    let aiResult: ProfileAIResult?
    let lastUpdated: Date
}
