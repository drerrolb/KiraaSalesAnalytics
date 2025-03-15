import Foundation
import SwiftUI
import TabularData

// ViewModel that loads the CSV and computes sums for numeric columns.
final class NumericSumViewModel: ObservableObject {
    // Each tuple contains the column name and the computed sum.
    @Published var sums: [(columnName: String, sum: Double)] = []
    @Published var isLoaded: Bool = false

    // Loads the CSV and computes the sums.
    func loadCSV() async {
        // Replace with your actual CSV file path.
        let filePath = "/Users/yourusername/Downloads/your-file.csv"
        let fileURL = URL(fileURLWithPath: filePath)
        
        do {
            // Load the CSV into a DataFrame.
            let dataFrame = try DataFrame(contentsOfCSVFile: fileURL)
            var results: [(String, Double)] = []
            
            // Iterate over each column in the DataFrame.
            for column in dataFrame.columns {
                let name = column.name
                // Skip columns that start with "article_" or "title_"
                if name.hasPrefix("article_") || name.hasPrefix("title_") {
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
            }
            
            // Update UI on the main thread.
            await MainActor.run {
                self.sums = results
                self.isLoaded = true
            }
        } catch {
            print("Error loading CSV file: \(error)")
        }
    }
}

// SwiftUI view to display the sums.
struct NumericSumView: View {
    @StateObject private var viewModel = NumericSumViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoaded {
                    List(viewModel.sums, id: \.columnName) { entry in
                        HStack {
                            Text(entry.columnName)
                            Spacer()
                            Text("\(entry.sum, specifier: "%.2f")")
                        }
                    }
                } else {
                    ProgressView("Loading CSV…")
                        .onAppear {
                            Task {
                                await viewModel.loadCSV()
                            }
                        }
                }
            }
            .navigationTitle("Numeric Column Sums")
            .padding()
        }
    }
}

// Preview provider for SwiftUI previews.
struct NumericSumView_Previews: PreviewProvider {
    static var previews: some View {
        NumericSumView()
    }
}