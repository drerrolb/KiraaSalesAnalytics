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
            
            // Data rows: iterate over each row in the DataFrame.
            ForEach(Array(dataFrame.rows.enumerated()), id: \.offset) { (_, row) in
                HStack {
                    ForEach(columnNames, id: \.self) { colName in
                        // Unwrap or show an empty string if nil.
                        Text("\(row[colName] ?? "")")
                            .frame(minWidth: 80, alignment: .leading)
                    }
                }
                Divider()
            }
        }
        // This makes the entire table expand horizontally within its parent.
        .frame(maxWidth: .infinity, alignment: .leading)
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
