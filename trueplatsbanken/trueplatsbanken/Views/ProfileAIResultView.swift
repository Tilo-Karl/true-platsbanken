import SwiftUI

struct ProfileAIResultView: View {
    let result: ProfileAIResult

    var body: some View {
        Section(AppStrings.profileAiSummary) {
            Text(result.summary)
        }

        Section(AppStrings.profileAiSeniority) {
            Text(result.seniority ?? AppStrings.profileAiNone)
        }

        Section(AppStrings.profileAiLocations) {
            Text(result.locations.joined(separator: ", "))
        }

        Section(AppStrings.profileAiRoles) {
            Text(result.roles.joined(separator: ", "))
        }

        Section(AppStrings.profileAiInferredRoles) {
            Text(result.inferredRoles.joined(separator: ", "))
        }

        Section(AppStrings.profileAiKeywords) {
            Text(result.keywords.joined(separator: ", "))
        }
    }
}
