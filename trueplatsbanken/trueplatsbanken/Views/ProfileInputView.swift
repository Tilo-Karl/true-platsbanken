import SwiftUI

struct ProfileInputView: View {
    @Binding var cvText: String
    let isExtracting: Bool
    let onExtract: () -> Void
    let onPaste: () -> Void
    let onReplace: () -> Void

    var body: some View {
        Section(AppStrings.profileSectionCv) {
            TextEditor(text: $cvText)
                .frame(minHeight: 140)
        }

        Section {
            HStack {
                Button(AppStrings.profilePasteCv, action: onPaste)
                Spacer()
                Button(AppStrings.profileReplaceCv, action: onReplace)
            }

            Button {
                onExtract()
            } label: {
                if isExtracting {
                    ProgressView()
                } else {
                    Text(AppStrings.profileExtract)
                }
            }
        }
    }
}
