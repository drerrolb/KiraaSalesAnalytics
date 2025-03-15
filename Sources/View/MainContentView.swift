import SwiftUI
import AppKit
import Foundation
import TabularData

// MARK: - Sidebar Items
enum SidebarItem: String, CaseIterable, Identifiable {
    case integration = "Integration"
    case variables = "Variables Browser"
    case sourceViewer = "Source Viewer"
    case configuration = "Configuration"
    // New menu option for numeric column sums.
    case numericSum = "Numeric Sum"
    
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
            case .sourceViewer:
                SourceContentView()
            case .configuration:
                ConfigurationView()
            case .numericSum:
                NumericSumView()  // New view for numeric sum
            }
        }
    }
    
    /// Called when a user taps a sidebar item.
    private func handleSelection(_ item: SidebarItem) {
        activeSheet = item
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
