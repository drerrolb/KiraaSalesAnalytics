import SwiftUI
import AppKit
import Foundation
import TabularData
import MongoSwiftSync  // Required for MongoDB operations

// MARK: - Sidebar Items
enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home Screen"
    case integration = "Integration"
    case variables = "Variables Browser"
    case sourceViewer = "Source Viewer"
    case configuration = "Configuration"
    case numericSum = "Numeric Sum"
    case downloadDocuments = "Download Documents"
    
    var id: String { rawValue }
}

// MARK: - MainContentView
struct MainContentView: View {
    @State private var selectedSidebarItem: SidebarItem? = .home

    var body: some View {
        NavigationSplitView {
            // Sidebar: Bind the list selection to the state variable.
            List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
                Text(item.rawValue)
                    .tag(item) // Ensure each row is tagged with the corresponding item.
            }
            .listStyle(.sidebar)
        } detail: {
            // Update the detail view based on the selected sidebar item.
            Group {
                switch selectedSidebarItem {
                case .home:
                    HomeContentView()
                case .integration:
                    IntegrationContentView()
                case .variables:
                    VariablesBrowserContentView()
                case .sourceViewer:
                    SourceContentView()
                case .configuration:
                    ConfigurationView()
                case .numericSum:
                    NumericSumView()
                case .downloadDocuments:
                    DownloadDocumentsView()
                case .none:
                    Text("Select an option from the sidebar")
                }
            }
        }
    }
}


// MARK: - Basic App Delegate for macOS
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
