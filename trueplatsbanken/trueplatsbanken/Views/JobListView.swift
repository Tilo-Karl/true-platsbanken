import SwiftUI

struct JobListView: View {
    @ObservedObject var viewModel: JobListViewModel
    @ObservedObject var taxonomyViewModel: TaxonomyViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    @State private var showOccupationSheet = false
    @State private var showLocationSheet = false
    @State private var showEmploymentTypeSheet = false
    @State private var showWorkingHoursSheet = false

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
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .top) {
            VStack(alignment: .leading, spacing: 12) {
                if let snapshot = taxonomyViewModel.snapshot {
                    JobFiltersBar(
                        filters: viewModel.filters,
                        recentFilters: viewModel.recentFilters,
                        onSelectRecent: { filter in
                            viewModel.updateFilters(filter)
                            viewModel.persistFiltersIfNeeded()
                        },
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
        .overlay {
            if viewModel.isLoading && viewModel.jobs.isEmpty {
                ProgressView(AppStrings.jobsLoading)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(AppStrings.jobsUnavailable, systemImage: "exclamationmark.triangle", description: Text(error))
            } else if viewModel.jobs.isEmpty {
                ContentUnavailableView(AppStrings.noJobs, systemImage: "tray", description: Text(AppStrings.checkBackLater))
            }
        }
        .navigationBarHidden(true)
        .refreshable {
            await viewModel.loadJobs()
        }
        .sheet(isPresented: $showOccupationSheet, onDismiss: viewModel.persistFiltersIfNeeded) {
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
        .sheet(isPresented: $showLocationSheet, onDismiss: viewModel.persistFiltersIfNeeded) {
            if let snapshot = taxonomyViewModel.snapshot {
                JobLocationPickerView(
                    municipalities: snapshot.municipalities,
                    selectedMunicipalities: viewModel.filters.municipalities,
                    onToggle: viewModel.toggleMunicipality,
                    onClear: viewModel.clearMunicipalityFilters
                )
            }
        }
        .sheet(isPresented: $showEmploymentTypeSheet, onDismiss: viewModel.persistFiltersIfNeeded) {
            if let snapshot = taxonomyViewModel.snapshot {
                JobEmploymentTypePickerView(
                    employmentTypes: snapshot.employmentTypes,
                    selectedEmploymentType: viewModel.filters.employmentType,
                    onSelect: viewModel.setEmploymentType
                )
            }
        }
        .sheet(isPresented: $showWorkingHoursSheet, onDismiss: viewModel.persistFiltersIfNeeded) {
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
