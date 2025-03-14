import SwiftUI
import AppKit
import Foundation
import SwiftUI
import TabularData


// MARK: - Sidebar Items
enum SidebarItem: String, CaseIterable, Identifiable {
    case integration = "Integration"
    case variables = "Variables Browser"
    case csvViewer = "CSV Viewer"
    case configuration = "Configuration"
    
    var id: String { rawValue }
}

// MARK: - MainContentView
struct MainContentView: View {
    @State private var activeSheet: SidebarItem? = nil

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List {
                ForEach(SidebarItem.allCases, id: \.self) { item in
                    Button(item.rawValue) {
                        handleSelection(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        } detail: {
            Text("Select an option from the sidebar to open a modal.")
        }
        // Present a SwiftUI sheet based on the selected sidebar item.
        .sheet(item: $activeSheet) { item in
            switch item {
            case .integration:
                IntegrationContentView()
            case .variables:
                VariablesBrowserContentView()
            case .csvViewer:
                CSVViewerContentView()
            case .configuration:
                ConfigurationView()
            }
        }
    }
    
    /// Called when a user taps a sidebar item.
    private func handleSelection(_ item: SidebarItem) {
        activeSheet = item
    }
}

// MARK: - ConfigurationView (Modal)
struct ConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Configuration")
                .font(.title)
            Text("Adjust settings here...")
            Button("Close") {
                dismiss() // Dismisses the modal sheet.
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(width: 400, height: 300)
        .padding()
    }
}

// MARK: - IntegrationContentView (Modal)
struct IntegrationContentView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Integration")
                .font(.title)
            Text("Integration settings or functionality goes here...")
            Button("Close") {
                dismiss() // Dismisses the modal sheet.
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(width: 400, height: 300)
        .padding()
    }
}

// MARK: - VariablesBrowserContentView (Modal)
struct VariablesBrowserContentView: View {
    @Environment(\.dismiss) private var dismiss

    // The merged dictionaries from your analytics code.
    let dictionary: [String: [String: String]] = AllAnalyticsDictionaries.allDictionaries

    var body: some View {
        NavigationView {
            List {
                ForEach(dictionary.keys.sorted(), id: \.self) { key in
                    NavigationLink(destination: VariableDetailView(variableKey: key, attributes: dictionary[key] ?? [:])) {
                        Text(key)
                    }
                }
            }
            .navigationTitle("Variables Browser")
            .toolbar {
                // Add a close button to the navigation bar.
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(width: 400, height: 300)
        .padding()
    }
}
// A dedicated view to display the CSV DataFrame.
struct CSVTableView: View {
    let dataFrame: DataFrame

    var body: some View {
        // Extract column names from the DataFrame.
        let columnNames = dataFrame.columns.map { $0.name }
        VStack(alignment: .leading, spacing: 8) {
            // Header row.
            HStack {
                ForEach(columnNames, id: \.self) { colName in
                    Text(colName)
                        .bold()
                        .frame(minWidth: 80, alignment: .leading)
                }
            }
            Divider()
            // Data rows: iterate over each row using the DataFrame's rows.
            ForEach(Array(dataFrame.rows.enumerated()), id: \.offset) { (rowIndex, row) in
                HStack {
                    ForEach(columnNames, id: \.self) { colName in
                        Text(String(describing: row[colName] as Any))
                            .frame(minWidth: 80, alignment: .leading)
                    }
                }
                Divider()
            }
        }
        .padding()
    }
}

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



// MARK: - Basic App
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct MyMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
    }
}
