import SwiftUI

struct JobListView: View {
    @ObservedObject var viewModel: JobListViewModel
    @ObservedObject var taxonomyViewModel: TaxonomyViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    @State private var showOccupationSheet = false
    @State private var showLocationSheet = false
    @State private var showEmploymentTypeSheet = false
    @State private var showWorkingHoursSheet = false
    @FocusState private var isSearchFocused: Bool
    
    // Consistent hero image for the Jobs tab
    private let heroImageName = "CVMatch11"
    private let heroHeight: CGFloat = 180
    private let headerOverlapFraction: CGFloat = 1.0 / 3.0

    var body: some View {
        let _ = languageStore.language

        HeroListScreen(
            heroImageName: heroImageName,
            heroHeight: heroHeight,
            topScrim: heroScrim,
            overlapFraction: headerOverlapFraction,
            bottomSpacing: AppSpacing.sectionGap,
            onRefresh: { await viewModel.loadJobs() }
        ) {
            jobsHeaderCard
        } content: {
            jobsSection
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showOccupationSheet) {
            if let snapshot = taxonomyViewModel.snapshot {
                JobOccupationPickerView(
                    occupationFields: snapshot.occupationFields,
                    occupations: snapshot.occupations,
                    selectedField: viewModel.filters.occupationField,
                    selectedOccupations: viewModel.filters.occupations,
                    onSelectField: viewModel.setOccupationField,
                    onToggleOccupation: viewModel.toggleOccupation,
                    onClear: viewModel.clearOccupationFilters
                )
            }
        }
        .sheet(isPresented: $showLocationSheet) {
            if let snapshot = taxonomyViewModel.snapshot {
                JobLocationPickerView(
                    municipalities: snapshot.municipalities,
                    selectedMunicipalities: viewModel.filters.municipalities,
                    onToggle: viewModel.toggleMunicipality,
                    onClear: viewModel.clearMunicipalityFilters
                )
            }
        }
        .sheet(isPresented: $showEmploymentTypeSheet) {
            if let snapshot = taxonomyViewModel.snapshot {
                JobEmploymentTypePickerView(
                    employmentTypes: snapshot.employmentTypes,
                    selectedEmploymentType: viewModel.filters.employmentType,
                    onSelect: viewModel.setEmploymentType
                )
            }
        }
        .sheet(isPresented: $showWorkingHoursSheet) {
            if let snapshot = taxonomyViewModel.snapshot {
                JobWorkingHoursPickerView(
                    workingHoursTypes: snapshot.workingHoursTypes,
                    selectedWorkingHoursType: viewModel.filters.workingHoursType,
                    onSelect: viewModel.setWorkingHoursType
                )
            }
        }
    }

    // MARK: - Jobs Header Card (Overlapping)
    private var jobsHeaderCard: some View {
        HeaderSummaryCard(
            title: AppStrings.jobsTitle,
            subtitle: AppStrings.vacanciesLabel(viewModel.jobs.count)
        ) {
            if taxonomyViewModel.snapshot != nil {
                JobFiltersBar(
                    filters: viewModel.filters,
                    onClear: { viewModel.clearFilters() },
                    onOccupationTap: { showOccupationSheet = true },
                    onLocationTap: { showLocationSheet = true },
                    onEmploymentTypeTap: { showEmploymentTypeSheet = true },
                    onWorkingHoursTap: { showWorkingHoursSheet = true }
                )
            } else {
                Text(AppStrings.filterLoading)
                    .font(AppFonts.meta)
                    .foregroundStyle(AppColors.brandBlack.opacity(0.7))
            }

            searchSection
        }
    }

    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: AppSpacing.cardGap / 2) {
            HStack(spacing: AppSpacing.cardGap / 2) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.brandBlueDark)
                TextField(AppStrings.jobsSearchPlaceholder, text: $viewModel.searchQuery)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .foregroundStyle(AppColors.brandBlack)
                    .submitLabel(.search)
                    .focused($isSearchFocused)
                    .onSubmit {
                        viewModel.commitSearchQuery()
                        isSearchFocused = false
                    }
                
                if viewModel.hasSearchQuery {
                    Button {
                        viewModel.searchQuery = ""
                        viewModel.clearSuggestions()
                        isSearchFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.brandBlueDark.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.cardGap)
            .padding(.vertical, 12)
            .background(AppColors.brandWhite.opacity(0.8)) // Glassy input
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Suggestions Dropdown
            if viewModel.shouldShowRecentSearches(isFocused: isSearchFocused) || !viewModel.visibleSuggestions.isEmpty {
                VStack(spacing: 0) {
                    let items = viewModel.shouldShowRecentSearches(isFocused: isSearchFocused) ? viewModel.recentSearches : viewModel.visibleSuggestions
                    
                    ForEach(items, id: \.self) { item in
                        Button {
                            viewModel.searchQuery = item
                            viewModel.commitSearchQuery()
                            isSearchFocused = false
                        } label: {
                            HStack {
                                Text(item).foregroundStyle(AppColors.brandBlack)
                                Spacer()
                                Image(systemName: "arrow.up.left").font(.caption2).opacity(0.3)
                            }
                            .padding(AppSpacing.cardGap)
                        }
                        .buttonStyle(.plain)
                        if item != items.last { Divider().padding(.horizontal) }
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            }
        }
    }

    // MARK: - Jobs Section
    @ViewBuilder
    private var jobsSection: some View {
        if viewModel.isLoading && viewModel.jobs.isEmpty {
            ProgressView().padding(40)
        } else if viewModel.jobs.isEmpty {
            ContentUnavailableView(AppStrings.noJobs, systemImage: "tray", description: Text(AppStrings.checkBackLater))
        } else {
            LazyVStack(spacing: AppSpacing.cardGap) {
                ForEach(viewModel.jobs) { job in
                    NavigationLink(value: job) {
                        JobCard(job: job)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        Task { await viewModel.loadMoreIfNeeded(currentJob: job) }
                    }
                }
            }
        }
    }

    private var heroScrim: LinearGradient {
        LinearGradient(
            colors: [AppColors.brandBlueDark.opacity(0.7), AppColors.brandBlueDark.opacity(0.2), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
