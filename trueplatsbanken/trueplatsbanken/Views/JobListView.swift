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

    var body: some View {
        let _ = languageStore.language

        ZStack {
            AppColors.brandWhite
                .ignoresSafeArea()

            List {
                ForEach(viewModel.jobs) { job in
                    NavigationLink(value: job) {
                        JobListRow(job: job)
                    }
                    .onAppear {
                        Task {
                            await viewModel.loadMoreIfNeeded(currentJob: job)
                        }
                    }
                }
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.jobs.isEmpty {
                    ProgressView(AppStrings.jobsLoading)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(AppStrings.jobsUnavailable, systemImage: "exclamationmark.triangle", description: Text(error))
                } else if viewModel.jobs.isEmpty {
                    ContentUnavailableView(AppStrings.noJobs, systemImage: "tray", description: Text(AppStrings.checkBackLater))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .top) {
            VStack(alignment: .leading, spacing: 12) {
                if taxonomyViewModel.snapshot != nil {
                    JobFiltersBar(
                        filters: viewModel.filters,
                        onClear: {
                            viewModel.clearFilters()
                        },
                        onOccupationTap: {
                            showOccupationSheet = true
                        },
                        onLocationTap: {
                            showLocationSheet = true
                        },
                        onEmploymentTypeTap: {
                            showEmploymentTypeSheet = true
                        },
                        onWorkingHoursTap: {
                            showWorkingHoursSheet = true
                        }
                    )
                } else {
                    Text(AppStrings.filterLoading)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.brandWhite.opacity(0.9))
                }

                VStack(spacing: 6) {
                    HStack(spacing: 8) {
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.brandWhite.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if viewModel.shouldShowRecentSearches(isFocused: isSearchFocused) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(AppStrings.searchRecentTitle)
                                .font(.footnote)
                                .foregroundStyle(AppColors.brandBlueDark.opacity(0.8))
                                .padding(.horizontal, 12)
                                .padding(.top, 8)

                            VStack(spacing: 0) {
                                ForEach(viewModel.recentSearches, id: \.self) { recent in
                                    Button {
                                        viewModel.searchQuery = recent
                                        viewModel.commitSearchQuery()
                                        isSearchFocused = false
                                    } label: {
                                        HStack {
                                            Text(recent)
                                                .foregroundStyle(AppColors.brandBlack)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                    }
                                    .buttonStyle(.plain)

                                    if recent != viewModel.recentSearches.last {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .background(AppColors.brandWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else if !viewModel.visibleSuggestions.isEmpty {
                        let suggestions = viewModel.visibleSuggestions
                        VStack(spacing: 0) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    viewModel.searchQuery = suggestion
                                    viewModel.commitSearchQuery()
                                    isSearchFocused = false
                                } label: {
                                    HStack {
                                        Text(suggestion)
                                            .foregroundStyle(AppColors.brandBlack)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)

                                if suggestion != suggestions.last {
                                    Divider()
                                }
                            }
                        }
                        .background(AppColors.brandWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else if viewModel.shouldShowEmptySuggestions(isFocused: isSearchFocused) {
                        HStack {
                            Text(AppStrings.searchSuggestionsNone)
                                .font(.footnote)
                                .foregroundStyle(AppColors.brandBlueDark.opacity(0.8))
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(AppColors.brandWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .onChange(of: isSearchFocused) { _, focused in
                    if !focused {
                        viewModel.clearSuggestions()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .padding(.top, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [AppColors.brandBlueDark, AppColors.brandBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(edges: .top)
            )
        }
        .navigationBarHidden(true)
        .refreshable {
            await viewModel.loadJobs()
        }
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
}
