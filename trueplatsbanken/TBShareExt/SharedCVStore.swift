import Foundation

enum SharedCVStore {
    private static let groupId = "group.com.tilodelau.jobtrek"
    private static let payloadKey = "shared.cv.payload"

    static func saveText(_ text: String) {
        let payload = SharedCVPayload(text: text, createdAt: Date())
        guard let data = try? JSONEncoder().encode(payload) else {
            return
        }
        UserDefaults(suiteName: groupId)?.set(data, forKey: payloadKey)
    }
}

private struct SharedCVPayload: Codable {
    let text: String
    let createdAt: Date
}
