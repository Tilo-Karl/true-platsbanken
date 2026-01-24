import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirestoreProfileStore: ProfileReading, ProfileWriting {
    private let store: Firestore

    init(store: Firestore = Firestore.firestore()) {
        self.store = store
    }

    func loadProfile() async throws -> Profile? {
        guard let userId = Auth.auth().currentUser?.uid else {
            return nil
        }

        let snapshot = try await store.collection("profiles").document(userId).getDocument()
        guard let data = snapshot.data() else {
            return nil
        }

        return Profile(
            id: data["id"] as? String ?? userId,
            userId: data["userId"] as? String ?? userId,
            name: data["name"] as? String ?? "",
            email: data["email"] as? String ?? "",
            phone: data["phone"] as? String ?? "",
            municipality: data["municipality"] as? String ?? "",
            employmentType: data["employmentType"] as? String ?? AppStrings.unknownLabel,
            skills: data["skills"] as? [String] ?? [],
            cvText: data["cvText"] as? String ?? ""
        )
    }

    func saveProfile(_ profile: Profile) async throws {
        let data: [String: Any] = [
            "id": profile.id,
            "userId": profile.userId,
            "name": profile.name,
            "email": profile.email,
            "phone": profile.phone,
            "municipality": profile.municipality,
            "employmentType": profile.employmentType,
            "skills": profile.skills,
            "cvText": profile.cvText
        ]

        try await store.collection("profiles").document(profile.id).setData(data, merge: true)
    }
}
