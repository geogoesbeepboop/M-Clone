import SwiftUI

/// Entry point for the Reports section, presented as a sheet from the Dashboard toolbar.
///
/// Lists the three available report types. Each navigates to a dedicated report view.
/// All report views share a single `ReportsViewModel` created here.
struct ReportsView: View {
    @Environment(\.transactionRepository) private var transactionRepo
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ReportsViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    List {
                        NavigationLink {
                            SpendingByCategoryReportView(viewModel: vm)
                        } label: {
                            Label("Spending by Category", systemImage: "chart.pie.fill")
                        }

                        NavigationLink {
                            CashFlowReportView(viewModel: vm)
                        } label: {
                            Label("Cash Flow", systemImage: "arrow.up.arrow.down.circle.fill")
                        }

                        NavigationLink {
                            MonthlyComparisonView(viewModel: vm)
                        } label: {
                            Label("Monthly Comparison", systemImage: "calendar.badge.clock")
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .tint(CrownTheme.primaryBlue)
                }
            }
            .onAppear {
                if viewModel == nil {
                    let vm = ReportsViewModel(transactionRepo: transactionRepo)
                    viewModel = vm
                    vm.loadData()
                }
            }
        }
    }
}
