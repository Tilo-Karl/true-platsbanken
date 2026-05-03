import UniformTypeIdentifiers
import SwiftUI
import PhotosUI

struct ProfileEditorView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel
    @ObservedObject var matchesViewModel: MatchResultsViewModel
    let isLiveMode: Bool
    let onUploadPhotos: ([Data]) async -> Void
    let onUploadFiles: ([URL]) async -> Void
    let onViewMatches: () -> Void
    @Binding var showUploadSheet: Bool
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showFileImporter = false
    @State private var showCvDetails = false
    @State private var heroImageName = "CVMatch11"
    @State private var uploadError: String?
    @State private var educationSheetTrack: EducationTrack?

    private let heroImages = ["CVMatch11", "CVMatch12"]
    private let heroHeight: CGFloat = 180
    private let headerOverlapFraction: CGFloat = 1.0 / 3.0

    var body: some View {
        ZStack(alignment: .top) {
            // Background fills everything behind the scroll
            AppBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HeroOverlapHeader(
                        heroImageName: heroImageName,
                        heroHeight: heroHeight,
                        topScrim: heroScrim,
                        overlapFraction: headerOverlapFraction,
                        bottomSpacing: AppSpacing.sectionGap
                    ) {
                        statusCard()
                    }

                    rolesCard()
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.bottom, AppSpacing.sectionGap)

                    if hasOpportunityProfileDebug {
                        opportunityProfileCard()
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.bottom, AppSpacing.sectionGap)
                    }

                    if hasEducationPath {
                        educationPathCard()
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.bottom, AppSpacing.sectionGap)
                    }

                    cvCard()
                        .padding(.horizontal, AppSpacing.screenPadding)
                }
                .padding(.bottom, 40)
            }
            .ignoresSafeArea(edges: .top)
            .coordinateSpace(name: "SCROLL")
            
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showUploadSheet) {
            uploadSheetContent()
        }
        .onChange(of: selectedPhotos) { _, items in
            handlePhotoSelection(items)
        }
        .sheet(item: $educationSheetTrack) { track in
            educationTrackSheet(for: track)
        }
        .onAppear {
            heroImageName = heroImages.randomElement() ?? heroImageName
        }
    }

    // MARK: - Sections

    private var heroScrim: LinearGradient {
        LinearGradient(
            colors: heroImageName == "CVMatch12"
                ? [AppColors.brandGreen.opacity(0.75), AppColors.brandGreen.opacity(0.25), .clear]
                : [AppColors.brandBlueDark.opacity(0.7), AppColors.brandBlueDark.opacity(0.2), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func statusCard() -> some View {
        HeaderSummaryCard(
            title: isLiveMode ? AppStrings.profileAiActive : AppStrings.profileDemoActive,
            subtitle: AppStrings.profileMatchesFound(matchesViewModel.matches.count)
        ) {
            Button(action: onViewMatches) {
                Text(AppStrings.profileViewMatches)
                    .font(AppFonts.body.weight(.semibold))
                    .foregroundStyle(AppColors.brandWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.brandBlueDark)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func rolesCard() -> some View {
        let roles = normalizedRoles(viewModel.aiResult?.roles)
        let inferred = normalizedRoles(viewModel.aiResult?.inferredRoles)

        return SectionCard(title: AppStrings.profileCardTitle) {
            VStack(alignment: .leading, spacing: 24) {
                if !roles.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppStrings.profileAiRoles)
                            .font(AppFonts.meta.weight(.semibold))
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 8) {
                            ForEach(roles, id: \.self) { role in
                                ChipView(text: role, style: .primary)
                            }
                        }
                    }
                }

                if !inferred.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppStrings.profileAiInferredRoles)
                            .font(AppFonts.meta.weight(.semibold))
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 8) {
                            ForEach(inferred, id: \.self) { role in
                                ChipView(text: role, style: .secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func cvCard() -> some View {
        SectionCard(title: AppStrings.profileSectionCv) {
            VStack(alignment: .leading, spacing: 20) {
                DisclosureGroup(isExpanded: $showCvDetails) {
                    TextEditor(text: .constant(viewModel.draft.cvText))
                        .frame(minHeight: 120)
                        .font(AppFonts.meta)
                        .padding(10)
                        .background(AppColors.brandWhite.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .disabled(true)
                        .padding(.top, 10)
                } label: {
                    Text(AppStrings.profileDetailsTitle)
                        .font(AppFonts.body)
                        .foregroundStyle(.secondary)
                }

                Button { showUploadSheet = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.doc.fill")
                        Text(AppStrings.profileUploadNewCv)
                    }
                    .font(AppFonts.body.weight(.semibold))
                    .foregroundStyle(AppColors.brandBlueDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.brandBlueDark.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private var hasEducationPath: Bool {
        sanitizedEducationPath.hasAnyItems
    }

    private var hasOpportunityProfileDebug: Bool {
        (viewModel.aiResult?.opportunityProfile ?? .empty).hasDebugContent
    }

    private func opportunityProfileCard() -> some View {
        let profile = viewModel.aiResult?.opportunityProfile ?? .empty

        return SectionCard(title: AppStrings.profileOpportunityTitle) {
            VStack(alignment: .leading, spacing: 16) {
                opportunityChipGroup(
                    title: AppStrings.profileOpportunityPrimaryDomains,
                    items: profile.primaryDomains
                )
                opportunityChipGroup(
                    title: AppStrings.profileOpportunitySecondaryDomains,
                    items: profile.secondaryDomains
                )
                opportunityChipGroup(
                    title: AppStrings.profileOpportunityCapabilities,
                    items: profile.transferableCapabilities
                )
                opportunityChipGroup(
                    title: AppStrings.profileOpportunityPivotFamilies,
                    items: profile.pivotOpportunityFamilies.map(\.label)
                )
            }
        }
    }

    @ViewBuilder
    private func opportunityChipGroup(title: String, items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(AppFonts.meta.weight(.semibold))
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        ChipView(text: item, style: .secondary)
                    }
                }
            }
        }
    }

    private func educationPathCard() -> some View {
        let path = sanitizedEducationPath

        return SectionCard(title: AppStrings.profileEducationTitle) {
            VStack(alignment: .leading, spacing: 20) {
                if !path.strengthen.isEmpty {
                    educationTrackSection(
                        title: AppStrings.profileEducationStrengthen,
                        items: path.strengthen,
                        track: .strengthen
                    )
                }

                if !path.pivot.isEmpty {
                    educationTrackSection(
                        title: AppStrings.profileEducationPivot,
                        items: path.pivot,
                        track: .pivot
                    )
                }
            }
        }
    }

    private func educationTrackSection(
        title: String,
        items: [ProfileEducationPathItem],
        track: EducationTrack
    ) -> some View {
        let previewItems = Array(items.prefix(2))

        return VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFonts.meta.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(Array(previewItems.enumerated()), id: \.offset) { _, item in
                EducationItemRow(item: item)
            }

            if items.count > 2 {
                Button {
                    educationSheetTrack = track
                } label: {
                    Text(AppStrings.profileEducationSeeMore)
                        .font(AppFonts.meta.weight(.semibold))
                        .foregroundStyle(AppColors.brandBlueDark)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    }

    private func educationTrackSheet(for track: EducationTrack) -> some View {
        let path = sanitizedEducationPath
        let items = track == .strengthen ? path.strengthen : path.pivot
        let title = track == .strengthen ? AppStrings.profileEducationStrengthen : AppStrings.profileEducationPivot

        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        EducationItemRow(item: item)
                    }
                }
                .padding(AppSpacing.screenPadding)
            }
            .background(AppBackground().ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.filterDone) {
                        educationSheetTrack = nil
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods
    
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            let dataItems = await loadPhotoData(from: items)
            if let error = UploadValidation.validatePhotoData(dataItems) {
                uploadError = error; selectedPhotos = []; return
            }
            uploadError = nil; showUploadSheet = false
            await onUploadPhotos(dataItems); selectedPhotos = []
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                if let error = UploadValidation.validateFileUrls(urls) {
                    uploadError = error
                    return
                }
                uploadError = nil
                showUploadSheet = false
                await onUploadFiles(urls)
            }
        case .failure:
            uploadError = AppStrings.profileImportFailed
        }
    }

    private func uploadSheetContent() -> some View {
        VStack(spacing: 16) {
            Capsule().frame(width: 40, height: 5).foregroundStyle(.secondary).padding(.top, 10)
            Text(AppStrings.profileHeroUpload).font(AppFonts.sectionTitle).padding(.top, 12)
            
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 2, matching: .images) {
                Text(AppStrings.matchesOverlayUploadPhoto)
                    .font(AppFonts.body.weight(.semibold))
                    .foregroundStyle(AppColors.brandWhite)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(AppColors.brandBlueDark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button { showFileImporter = true } label: {
                Text(AppStrings.matchesOverlayUploadFile)
                    .font(AppFonts.body.weight(.semibold))
                    .foregroundStyle(AppColors.brandBlueDark)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(AppColors.brandBlueDark.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            if let uploadError {
                Text(uploadError).font(AppFonts.meta).foregroundStyle(.red).padding(.top, 8)
            }
            Spacer()
        }
        .padding(20)
        // Present file picker from the sheet host to avoid "already presenting" conflicts.
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
    }

    private func loadPhotoData(from items: [PhotosPickerItem]) async -> [Data] {
        var results: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                results.append(data)
            }
        }
        return results
    }

    private func normalizedRoles(_ roles: [String]?) -> [String] {
        guard let roles = roles else { return [] }
        return roles.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    private var sanitizedEducationPath: ProfileEducationPath {
        dedupedEducationPath(viewModel.aiResult?.educationPath ?? .empty)
    }

    private func dedupedEducationPath(_ path: ProfileEducationPath) -> ProfileEducationPath {
        ProfileEducationPath(
            strengthen: dedupedEducationItems(path.strengthen),
            pivot: dedupedEducationItems(path.pivot)
        )
    }

    private func dedupedEducationItems(_ items: [ProfileEducationPathItem]) -> [ProfileEducationPathItem] {
        var bestByKey: [String: ProfileEducationPathItem] = [:]
        var order: [String] = []

        for item in items {
            let key = educationDedupeKey(item)
            if let existing = bestByKey[key] {
                if shouldReplace(existing: existing, candidate: item) {
                    bestByKey[key] = item
                }
                continue
            }
            bestByKey[key] = item
            order.append(key)
        }

        return order.compactMap { bestByKey[$0] }
    }

    private func shouldReplace(existing: ProfileEducationPathItem, candidate: ProfileEducationPathItem) -> Bool {
        if candidate.confidence != existing.confidence {
            return candidate.confidence > existing.confidence
        }

        let existingDate = educationDateSortValue(existing.startDate)
        let candidateDate = educationDateSortValue(candidate.startDate)
        if existingDate != candidateDate {
            return candidateDate < existingDate
        }

        let existingTitle = existing.courseTitle.localizedLowercase
        let candidateTitle = candidate.courseTitle.localizedLowercase
        return candidateTitle < existingTitle
    }

    private func educationDedupeKey(_ item: ProfileEducationPathItem) -> String {
        let track = item.track.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let title = normalizeEducationKeyText(item.courseTitle)
        let provider = normalizeEducationKeyText(item.provider ?? "")
        let startDate = normalizeEducationDateKey(item.startDate)
        return "\(track)::\(title)::\(provider)::\(startDate)"
    }

    private func normalizeEducationKeyText(_ raw: String) -> String {
        let pieces = raw
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        var compacted: [String] = []
        for piece in pieces {
            if compacted.last == piece { continue }
            compacted.append(piece)
        }
        return compacted.joined(separator: " ")
    }

    private func normalizeEducationDateKey(_ raw: String?) -> String {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let date = parseEducationDate(raw) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func educationDateSortValue(_ raw: String?) -> Int {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let date = parseEducationDate(raw) else {
            return Int.max
        }
        return Int(date.timeIntervalSince1970)
    }

    private func parseEducationDate(_ raw: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let full = iso.date(from: raw) {
            return full
        }

        let simple = DateFormatter()
        simple.calendar = Calendar(identifier: .gregorian)
        simple.locale = Locale(identifier: "en_US_POSIX")
        simple.timeZone = TimeZone(secondsFromGMT: 0)
        simple.dateFormat = "yyyy-MM-dd"
        return simple.date(from: raw)
    }

}

private enum EducationTrack: String, Identifiable {
    case strengthen
    case pivot

    var id: String { rawValue }
}

// MARK: - Reusable Components

private struct ChipView: View {
    enum Style { case primary; case secondary }
    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .font(AppFonts.meta.weight(.semibold))
            .foregroundStyle(style == .primary ? AppColors.brandBlueDark : AppColors.brandBlack.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(style == .primary ? AppColors.brandBlueDark.opacity(0.12) : AppColors.brandBlack.opacity(0.05))
            .clipShape(Capsule())
    }
}

private struct EducationItemRow: View {
    @Environment(\.openURL) private var openURL
    let item: ProfileEducationPathItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.courseTitle)
                .font(AppFonts.body.weight(.semibold))
                .foregroundStyle(AppColors.brandBlueDark)

            Text(providerLine)
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.brandBlack.opacity(0.7))

            if let startLabel {
                Text(startLabel)
                    .font(AppFonts.meta)
                    .foregroundStyle(AppColors.brandBlack.opacity(0.65))
            }

            Text(item.reason)
                .font(AppFonts.meta)
                .foregroundStyle(AppColors.brandBlack.opacity(0.65))

            if let courseURL {
                Link(destination: courseURL) {
                    Text(AppStrings.profileEducationOpenCourse)
                        .font(AppFonts.meta.weight(.semibold))
                        .foregroundStyle(AppColors.brandBlueDark)
                        .padding(.top, 4)
                }
            } else if let courseIdLine {
                Text(courseIdLine)
                    .font(AppFonts.meta)
                    .foregroundStyle(AppColors.brandBlack.opacity(0.55))
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.brandWhite.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            guard let courseURL else { return }
            openURL(courseURL)
        }
    }

    private var providerLine: String {
        let provider = item.provider?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if provider.isEmpty { return AppStrings.profileEducationProviderUnknown }
        return provider
    }

    private var startLabel: String? {
        guard let startDate = item.startDate,
              let parsed = parseISODate(startDate) else {
            return nil
        }
        let formatted = dateFormatter.string(from: parsed)
        return AppStrings.profileEducationStarts(formatted)
    }

    private var courseURL: URL? {
        guard let raw = item.courseUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }
        return url
    }

    private var courseIdLine: String? {
        guard let courseId = item.courseId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !courseId.isEmpty else {
            return nil
        }
        return AppStrings.profileEducationCourseId(courseId)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private func parseISODate(_ raw: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let full = iso.date(from: raw) {
            return full
        }

        let simple = DateFormatter()
        simple.calendar = Calendar(identifier: .gregorian)
        simple.locale = Locale(identifier: "en_US_POSIX")
        simple.timeZone = TimeZone(secondsFromGMT: 0)
        simple.dateFormat = "yyyy-MM-dd"
        return simple.date(from: raw)
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    var body: some View { FlowLayoutContainer(spacing: spacing) { content } }
}

private struct FlowLayoutContainer: Layout {
    let spacing: CGFloat
    init(spacing: CGFloat) { self.spacing = spacing }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            let proposedNextWidth = rowWidth == 0 ? size.width : rowWidth + spacing + size.width
            if proposedNextWidth > maxWidth, rowWidth > 0 {
                usedWidth = max(usedWidth, rowWidth)
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }

            rowWidth = rowWidth == 0 ? size.width : rowWidth + spacing + size.width
            rowHeight = max(rowHeight, size.height)
        }

        usedWidth = max(usedWidth, rowWidth)
        let finalWidth = proposal.width ?? usedWidth
        return CGSize(width: finalWidth, height: totalHeight + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
