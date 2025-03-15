import Foundation
import SwiftUI
import TabularData

@MainActor
final class SourceTableViewModel: ObservableObject {
    @Published var dataFrame: DataFrame = DataFrame()
    @Published var rowsCache: [DataFrame.Row] = []
    @Published var isLoaded: Bool = false
    let pageSize: Int = 100
    
    // Computed property for column names.
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
            
            // Update properties on the main actor after the view has been laid out.
            await MainActor.run {
                self.dataFrame = df
                self.rowsCache = Array(df.rows)
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

struct SourceContentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 0
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
            
            // Main content area displaying the grid.
            SourceTableView(viewModel: viewModel, currentPage: currentPage)
            
            // Pagination controls.
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
        .frame(minWidth: 600, minHeight: 400)
        .padding()
        // Load CSV data after the view appears.
        .task {
            await viewModel.loadCSV()
        }
    }
}
