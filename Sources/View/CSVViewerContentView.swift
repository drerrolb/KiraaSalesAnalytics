import SwiftUI

struct CSVViewerContentView: View {
    var body: some View {
        CSVTableView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                print("CSVViewerContentView appeared.")
            }
    }
}

struct CSVTableView: View {
    @State private var headers: [String] = []
    @State private var allRows: [[String]] = []
    @State private var errorMessage: String? = nil
    @State private var currentPage: Int = 1
    
    private let rowsPerPage = 50
    
    var totalPages: Int {
        allRows.isEmpty ? 1 : (allRows.count + rowsPerPage - 1) / rowsPerPage
    }
    
    var currentPageRows: [[String]] {
        let start = (currentPage - 1) * rowsPerPage
        let end = min(start + rowsPerPage, allRows.count)
        return start < allRows.count ? Array(allRows[start..<end]) : []
    }
    
    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .onAppear { print("Error loading CSV: \(errorMessage)") }
            } else if headers.isEmpty && allRows.isEmpty {
                Text("Loading CSV data...")
                    .onAppear(perform: loadCSV)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        // Header row.
                        HStack(spacing: 0) {
                            ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                                Text(header)
                                    .fontWeight(.bold)
                                    .frame(minWidth: 100, alignment: .leading)
                                    .padding(5)
                                    .border(Color.gray)
                            }
                        }
                        .background(Color.secondary.opacity(0.2))
                        
                        // Data rows.
                        ForEach(0..<currentPageRows.count, id: \.self) { rowIndex in
                            HStack(spacing: 0) {
                                ForEach(Array(currentPageRows[rowIndex].enumerated()), id: \.offset) { _, column in
                                    Text(column)
                                        .frame(minWidth: 100, alignment: .leading)
                                        .padding(5)
                                        .border(Color.gray)
                                }
                            }
                        }
                    }
                }
                // Pagination controls.
                HStack {
                    Button("Previous") {
                        if currentPage > 1 {
                            currentPage -= 1
                            print("Moved to previous page: \(currentPage)")
                        }
                    }
                    .disabled(currentPage <= 1)
                    
                    Text("Page \(currentPage) of \(totalPages)")
                    
                    Button("Next") {
                        if currentPage < totalPages {
                            currentPage += 1
                            print("Moved to next page: \(currentPage)")
                        }
                    }
                    .disabled(currentPage >= totalPages)
                }
                .padding()
            }
        }
        .padding()
        .onAppear { print("CSVTableView appeared.") }
    }
    
    func loadCSV() {
        let filePath: String = {
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                return documentsDirectory.appendingPathComponent("source-sales.csv").path
            } else {
                return "/Users/e2mq173/Projects/dataframes/source-sales.csv"
            }
        }()
        
        do {
            let content = try String(contentsOfFile: filePath)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard let headerLine = lines.first else {
                errorMessage = "CSV file is empty."
                print("CSV file is empty.")
                return
            }
            headers = headerLine.components(separatedBy: ",")
            allRows = lines.dropFirst().map { $0.components(separatedBy: ",") }
            print("CSV loaded successfully. Total rows: \(allRows.count)")
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load CSV: \(error.localizedDescription)")
        }
    }
}