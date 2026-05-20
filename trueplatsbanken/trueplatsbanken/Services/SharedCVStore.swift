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

    static func consumeText() -> String? {
        guard let defaults = UserDefaults(suiteName: groupId),
              let data = defaults.data(forKey: payloadKey),
              let payload = try? JSONDecoder().decode(SharedCVPayload.self, from: data) else {
            return nil
        }
        defaults.removeObject(forKey: payloadKey)
        return payload.text
    }
}

private struct SharedCVPayload: Codable {
    let text: String
    let createdAt: Date
}
