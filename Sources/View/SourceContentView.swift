import Foundation
import SwiftUI
import TabularData

// Define a custom key for grouping that conforms to Hashable.
struct GroupKey: Hashable, Comparable {
    let date: String
    let measure: String
    
    static func < (lhs: GroupKey, rhs: GroupKey) -> Bool {
        if lhs.date != rhs.date {
            return lhs.date < rhs.date
        }
        return lhs.measure < rhs.measure
    }
}

@MainActor
final class SourceTableViewModel: ObservableObject {
    @Published var dataFrame: DataFrame = DataFrame()
    @Published var rowsCache: [DataFrame.Row] = []
    @Published var aggregatedDataFrame: DataFrame = DataFrame()
    @Published var isLoaded: Bool = false
    let pageSize: Int = 100

    // Computed property for column names of the detailed view.
    var columnNames: [String] {
        dataFrame.columns.map { $0.name }
    }
    
    func loadCSV() async {
        let filePath = "/Users/e2mq173/Downloads/source-sales.csv"
        let fileURL = URL(fileURLWithPath: filePath)
        do {
            let df = try DataFrame(contentsOfCSVFile: fileURL)
            
            // Define the expected headers.
            let expectedHeaders: [String] = {
                var headers = ["SA01DATE"]
                for i in 1...99 {
                    headers.append(String(format: "SA01F%02d", i))
                }
                headers.append("SA01MEASURE")
                headers.append("SA01VALUE")
                return headers
            }()
            
            let dfHeaders = df.columns.map { $0.name }
            guard dfHeaders == expectedHeaders else {
                print("CSV file headers do not match expected headers.")
                return
            }
            
            // Cache all rows.
            let dfRows = Array(df.rows)
            
            // Compute the aggregated DataFrame.
            // Group by SA01DATE and SA01MEASURE, summing SA01VALUE.
            var groups: [GroupKey: Double] = [:]
            for row in dfRows {
                // Force cast SA01DATE to a string.
                let date = String(describing: row["SA01DATE"] ?? "")
                let measure = row["SA01MEASURE"] as? String ?? ""
                let key = GroupKey(date: date, measure: measure)
                let value: Double
                if let v = row["SA01VALUE"] as? Double {
                    value = v
                } else if let vStr = row["SA01VALUE"] as? String, let v = Double(vStr) {
                    value = v
                } else {
                    value = 0.0
                }
                groups[key, default: 0.0] += value
            }
            
            // Sort the keys for a deterministic order.
            let sortedKeys = groups.keys.sorted()
            let aggregatedDates = sortedKeys.map { $0.date }
            let aggregatedMeasures = sortedKeys.map { $0.measure }
            // Cast the aggregated sums to integers.
            let aggregatedValues = sortedKeys.map { Int(groups[$0]!) }
            
            let aggregatedDF = DataFrame(columns: [
                Column(name: "SA01DATE", contents: aggregatedDates).eraseToAnyColumn(),
                Column(name: "SA01MEASURE", contents: aggregatedMeasures).eraseToAnyColumn(),
                Column(name: "SA01VALUE", contents: aggregatedValues).eraseToAnyColumn()
            ])
            
            // Update the model on the main thread.
            await MainActor.run {
                self.dataFrame = df
                self.rowsCache = dfRows
                self.aggregatedDataFrame = aggregatedDF
                self.isLoaded = true
            }
        } catch {
            print("Error loading CSV file: \(error)")
        }
    }
    
    func rows(forPage page: Int) -> [DataFrame.Row] {
        let startIndex = page * pageSize
        let endIndex = min(startIndex + pageSize, rowsCache.count)
        return Array(rowsCache[startIndex..<endIndex])
    }
    
    var totalPages: Int {
        return (rowsCache.count + pageSize - 1) / pageSize
    }
}

/// Detailed (paginated) table view for the CSV data.
struct SourceTableView: View {
    @ObservedObject var viewModel: SourceTableViewModel
    let currentPage: Int
    
    var body: some View {
        if !viewModel.isLoaded {
            ProgressView("Loading CSV…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView([.vertical, .horizontal]) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header row.
                    HStack(spacing: 0) {
                        ForEach(viewModel.columnNames, id: \.self) { colName in
                            Text(colName)
                                .bold()
                                .frame(width: 80, alignment: .leading)
                                .padding(5)
                                .background(Color.gray.opacity(0.2))
                                .border(Color.gray, width: 0.5)
                        }
                    }
                    // Data rows.
                    ForEach(Array(viewModel.rows(forPage: currentPage).enumerated()), id: \.offset) { rowIndex, row in
                        HStack(spacing: 0) {
                            ForEach(viewModel.columnNames, id: \.self) { colName in
                                Text("\(row[colName] ?? "")")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(width: 80, alignment: .leading)
                                    .padding(5)
                                    .border(Color.gray.opacity(0.5), width: 0.5)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

/// Aggregated table view showing grouped data.
struct SourceAggregatedTableView: View {
    let aggregatedDataFrame: DataFrame
    
    var columnNames: [String] {
         aggregatedDataFrame.columns.map { $0.name }
    }
    
    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row with columns twice as wide.
                HStack(spacing: 0) {
                    ForEach(columnNames, id: \.self) { colName in
                        Text(colName)
                            .bold()
                            // Right align SA01VALUE header, left align others.
                            .frame(width: 160, alignment: colName == "SA01VALUE" ? .trailing : .leading)
                            .padding(5)
                            .background(Color.gray.opacity(0.2))
                            .border(Color.gray, width: 0.5)
                    }
                }
                // Data rows.
                ForEach(Array(aggregatedDataFrame.rows.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(columnNames, id: \.self) { colName in
                            Text("\(row[colName] ?? (colName == "SA01VALUE" ? 0 : ""))")
                                .lineLimit(1)
                                .truncationMode(.tail)
                                // Right align SA01VALUE cells, left align others.
                                .frame(width: 160, alignment: colName == "SA01VALUE" ? .trailing : .leading)
                                .padding(5)
                                .border(Color.gray.opacity(0.5), width: 0.5)
                        }
                    }
                }
            }
            .padding()
        }
    }
}


/// The main content view including a segmented control to toggle between detailed and aggregated views.
struct SourceContentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 0
    // 0 = Detailed, 1 = Aggregated
    @State private var selectedView: Int = 0
    @StateObject private var viewModel = SourceTableViewModel()
    
    var body: some View {
        VStack {
            // Header with title and close button.
            HStack {
                Text("CSV Viewer")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding([.horizontal, .top])
            Divider()
            
            // Segmented control for switching views.
            Picker("View", selection: $selectedView) {
                Text("Detailed").tag(0)
                Text("Aggregated").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Main content area: show one of the two table views.
            if selectedView == 0 {
                SourceTableView(viewModel: viewModel, currentPage: currentPage)
            } else {
                if viewModel.isLoaded {
                    SourceAggregatedTableView(aggregatedDataFrame: viewModel.aggregatedDataFrame)
                } else {
                    ProgressView("Loading CSV…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            // Show pagination controls only in the detailed view.
            if selectedView == 0 {
                HStack {
                    Button("Previous") {
                        if currentPage > 0 { currentPage -= 1 }
                    }
                    .disabled(currentPage == 0)
                    
                    Spacer()
                    Text("Page \(currentPage + 1) of \(max(viewModel.totalPages, 1))")
                    Spacer()
                    
                    Button("Next") {
                        if currentPage < viewModel.totalPages - 1 { currentPage += 1 }
                    }
                    .disabled(currentPage >= viewModel.totalPages - 1)
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .padding()
        // Load CSV data after the view appears.
        .task {
            await viewModel.loadCSV()
        }
    }
}
