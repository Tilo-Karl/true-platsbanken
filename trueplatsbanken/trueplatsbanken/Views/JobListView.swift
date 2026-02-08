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

        List {
            Section {
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
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .sheet(isPresented: $showOccupationSheet, onDismiss: viewModel.persistFiltersIfNeeded) {
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
                    .sheet(isPresented: $showLocationSheet, onDismiss: viewModel.persistFiltersIfNeeded) {
                        JobLocationPickerView(
                            municipalities: snapshot.municipalities,
                            selectedMunicipalities: viewModel.filters.municipalities,
                            onToggle: viewModel.toggleMunicipality,
                            onClear: viewModel.clearMunicipalityFilters
                        )
                    }
                    .sheet(isPresented: $showEmploymentTypeSheet, onDismiss: viewModel.persistFiltersIfNeeded) {
                        JobEmploymentTypePickerView(
                            employmentTypes: snapshot.employmentTypes,
                            selectedEmploymentType: viewModel.filters.employmentType,
                            onSelect: viewModel.setEmploymentType
                        )
                    }
                    .sheet(isPresented: $showWorkingHoursSheet, onDismiss: viewModel.persistFiltersIfNeeded) {
                        JobWorkingHoursPickerView(
                            workingHoursTypes: snapshot.workingHoursTypes,
                            selectedWorkingHoursType: viewModel.filters.workingHoursType,
                            onSelect: viewModel.setWorkingHoursType
                        )
                    }
                } else {
                    Text(AppStrings.filterLoading)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                ForEach(viewModel.jobs) { job in
                    NavigationLink(value: job) {
                        JobListRow(job: job)
                    }
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.isLoading && viewModel.jobs.isEmpty {
                ProgressView(AppStrings.jobsLoading)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(AppStrings.jobsUnavailable, systemImage: "exclamationmark.triangle", description: Text(error))
            } else if viewModel.jobs.isEmpty {
                ContentUnavailableView(AppStrings.noJobs, systemImage: "tray", description: Text(AppStrings.checkBackLater))
            }
        }
        .navigationTitle(AppStrings.jobsTitle)
        .refreshable {
            await viewModel.loadJobs()
        }
    }
}
