//
//  NumericSumViewModel.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 15/3/2025.
//

import Foundation
import SwiftUI
import TabularData
import AppKit

// Define a Codable structure for saving the sum results.
struct SumEntry: Codable {
    let columnName: String
    let sum: Double
}

@MainActor
final class NumericSumViewModel: ObservableObject {
    // Each tuple contains the column name and the computed sum.
    @Published var sums: [(columnName: String, sum: Double)] = []
    @Published var isLoaded: Bool = false
    // Property to track progress (from 0.0 to 1.0)
    @Published var progress: Double = 0.0
    
    // URL to store the saved results.
    private var savedSumsURL: URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("NumericSums.json")
    }
    
    /// Loads the saved sums if available, otherwise calculates them.
    func loadData() async {
        if let savedEntries = loadSavedSums() {
            // Display the preloaded values.
            self.sums = savedEntries.map { ($0.columnName, $0.sum) }
            self.isLoaded = true
            self.progress = 1.0
        } else {
            // No saved results; calculate the totals.
            await loadDataframeCSV()
        }
    }
    
    /// Recalculate the sums from the CSV.
    func recalculate() async {
        // Reset state.
        self.sums = []
        self.isLoaded = false
        self.progress = 0.0
        await loadDataframeCSV()
    }
    
    /// Loads the CSV and computes the sums.
    func loadDataframeCSV() async {
        // Replace with your actual CSV file path.
        let filePath = "/Users/e2mq173/Documents/dataframe.csv"
        let fileURL = URL(fileURLWithPath: filePath)
        
        do {
            // Load the CSV into a DataFrame.
            let dataFrame = try DataFrame(contentsOfCSVFile: fileURL)
            var results: [(String, Double)] = []
            
            // Determine total number of columns to process.
            let totalColumns = dataFrame.columns.count
            var processedColumns = 0
            
            // Iterate over each column in the DataFrame.
            for column in dataFrame.columns {
                let name = column.name
                
                // Skip columns that start with "article_" or "title_"
                if name.hasPrefix("article_") || name.hasPrefix("title_") {
                    processedColumns += 1
                    self.progress = Double(processedColumns) / Double(totalColumns)
                    await Task.yield() // Yield to update UI
                    continue
                }
                
                // Sum the numeric values in the column.
                var columnSum: Double = 0.0
                for row in dataFrame.rows {
                    if let value = row[name] {
                        if let doubleValue = value as? Double {
                            columnSum += doubleValue
                        } else if let intValue = value as? Int {
                            columnSum += Double(intValue)
                        } else if let stringValue = value as? String, let doubleValue = Double(stringValue) {
                            columnSum += doubleValue
                        }
                    }
                }
                results.append((name, columnSum))
                processedColumns += 1
                self.progress = Double(processedColumns) / Double(totalColumns)
                await Task.yield() // Yield to update UI
            }
            
            // Finalize loading.
            self.sums = results
            self.isLoaded = true
            self.progress = 1.0
            saveSums()
        } catch {
            print("Error loading CSV file: \(error)")
        }
    }
    
    /// Saves the computed sums to disk as JSON.
    private func saveSums() {
        let entries = self.sums
            .filter { $0.sum != 0 }
            .map { SumEntry(columnName: $0.columnName, sum: $0.sum) }
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(entries)
            try data.write(to: savedSumsURL)
        } catch {
            print("Error saving sums: \(error)")
        }
    }
    
    /// Loads saved sums from disk if available.
    private func loadSavedSums() -> [SumEntry]? {
        let url = savedSumsURL
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode([SumEntry].self, from: data)
    }
}

// SwiftUI view to display the sums.
struct NumericSumView: View {
    @StateObject private var viewModel = NumericSumViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Text("Numeric Column Sums")
                    .font(.largeTitle)
                    .padding(.top)
                Spacer()
                Button("Recalculate") {
                    Task {
                        await viewModel.recalculate()
                    }
                }
                .padding(.top)
                Button("Copy to Clipboard") {
                    copySumsToClipboard()
                }
                .padding(.top)
                Button("Close") {
                    dismiss()
                }
                .padding(.top)
            }
            .padding([.leading, .trailing])
            
            if viewModel.isLoaded {
                List(viewModel.sums, id: \.columnName) { entry in
                    HStack {
                        Text(entry.columnName)
                        Spacer()
                        Text("\(entry.sum, specifier: "%.2f")")
                    }
                }
            } else {
                // Display progress bar and percentage while loading.
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    Text("Loading... \(Int(viewModel.progress * 100))%")
                        .font(.subheadline)
                }
                .padding()
                .onAppear {
                    Task {
                        await viewModel.loadData()
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400) // Ensures a windowed appearance.
    }
    
    // Function to copy the saved sums to the clipboard as a table formatted for Excel.
    private func copySumsToClipboard() {
        // Create a header row and tab-separated values.
        var output = "Column Name\tSum\n"
        for entry in viewModel.sums {
            output.append("\(entry.columnName)\t\(entry.sum)\n")
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }
}

// Preview provider for SwiftUI previews.
struct NumericSumView_Previews: PreviewProvider {
    static var previews: some View {
        NumericSumView()
    }
}
