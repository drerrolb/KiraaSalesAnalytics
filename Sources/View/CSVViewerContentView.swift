
import Foundation
import SwiftUI
import TabularData

// MARK: - CSVViewerContentView (Modal)
struct CSVViewerContentView: View {
    @Environment(\.dismiss) private var dismiss

    // Build test data using the DataFrame initializer that takes an array of AnyColumn.
    @State private var dataFrame: DataFrame? = {
        let names = ["Alice", "Bob", "Charlie"]
        let ages = [25, 30, 35]
        let cities = ["New York", "London", "Paris"]

        let nameColumn = Column<String>(name: "Name", contents: names)
        let ageColumn = Column<Int>(name: "Age", contents: ages)
        let cityColumn = Column<String>(name: "City", contents: cities)
        
        // Construct the DataFrame from an array of columns.
        return DataFrame(columns: [
            nameColumn.eraseToAnyColumn(),
            ageColumn.eraseToAnyColumn(),
            cityColumn.eraseToAnyColumn()
        ])
    }()

    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            Group {
                if let df = dataFrame {
                    ScrollView([.vertical, .horizontal]) {
                        CSVTableView(dataFrame: df)
                    }
                } else if let errorMessage = errorMessage {
                    VStack {
                        Text("Error loading CSV:")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ProgressView("Loading CSV...")
                }
            }
            .navigationTitle("CSV Viewer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .padding()
    }
}

