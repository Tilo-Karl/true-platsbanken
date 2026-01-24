import Foundation

struct ProfileDraft: Hashable {
    var userId: String = ""
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var municipality: String = ""
    var employmentType: String = "any"
    var skillsText: String = ""
    var cvText: String = ""
}
