import SwiftUI
import AppKit

// MARK: - WindowStore to retain open NSWindow instances

final class WindowStore: ObservableObject {
    // Keeps a strong reference to all open child windows.
    @Published var windows: [NSWindow] = []
}

// MARK: - Sidebar Menu Items

enum SidebarItem: String, CaseIterable, Identifiable {
    case integration = "Integration"
    case variables = "Variables Browser"
    case csvViewer = "CSV Viewer"
    
    var id: String { self.rawValue }
}

// MARK: - NSViewControllerRepresentable for Background ViewController

struct ViewControllerWrapper: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> ViewController {
        // Instantiate your existing Cocoa ViewController.
        return ViewController()
    }
    
    func updateNSViewController(_ nsViewController: ViewController, context: Context) {
        // No dynamic updates required.
    }
}

// MARK: - MainContentView with Background and Sidebar

struct MainContentView: View {
    @StateObject private var windowStore = WindowStore() // Retain child windows
    
    var body: some View {
        ZStack {
            // Background: Embed the Cocoa ViewController's view.
            ViewControllerWrapper()
                .ignoresSafeArea()
                .allowsHitTesting(false) // So it does not intercept foreground events.
            
            // Foreground: The sidebar (NavigationSplitView).
            NavigationSplitView {
                List {
                    ForEach(SidebarItem.allCases, id: \.self) { item in
                        Button(action: {
                            print("Button tapped: \(item.rawValue)")
                            openWindow(for: item)
                        }) {
                            Text(item.rawValue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(SidebarListStyle())
                .frame(minWidth: 200)
            } detail: {
                // Detail area placeholder.
                Text("Select an option from the sidebar to open as a subwindow")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            print("MainContentView appeared with background ViewController.")
        }
    }
    
    // Returns the appropriate view for the given sidebar item.
    @ViewBuilder
    private func viewForSidebarItem(_ item: SidebarItem) -> some View {
        switch item {
        case .integration:
            IntegrationView()
        case .variables:
            VariablesBrowserContentView()
        case .csvViewer:
            CSVViewerContentView()
        }
    }
    
    // Creates a new NSWindow displaying the view corresponding to the sidebar item,
    private func openWindow(for item: SidebarItem) {
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.center()
        newWindow.title = item.rawValue
        newWindow.contentView = NSHostingView(rootView: viewForSidebarItem(item))
        
        // For CSV Viewer, open as a normal window to avoid the crash.
        if item == .csvViewer {
            DispatchQueue.main.async {
                newWindow.makeKeyAndOrderFront(nil)
                print("Opened \(item.rawValue) as a normal window (child attachment skipped).")
            }
        } else {
            // Ensure window operations occur on the main thread.
            DispatchQueue.main.async {
                if let mainWindow = NSApplication.shared.windows.first(where: { $0.isMainWindow }) {
                    mainWindow.addChildWindow(newWindow, ordered: .above)
                    print("Attached \(item.rawValue) as a child of the main window.")
                } else {
                    newWindow.makeKeyAndOrderFront(nil)
                    print("Main window not found. Opened \(item.rawValue) as a normal window.")
                }
            }
        }
        
        // Retain the window so it remains visible.
        windowStore.windows.append(newWindow)
        print("Opened new window for: \(item.rawValue)")
    }
    
    
    
}

// MARK: - Integration View

struct IntegrationView: View {
    @State private var statusMessage = "Ready"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Integration")
                .font(.title)
            Text(statusMessage)
            Button("Run Integration") {
                print("Run Integration button tapped.")
                Task {
                    await runIntegration()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            print("IntegrationView appeared with status: \(statusMessage)")
        }
    }
    
    func runIntegration() async {
        statusMessage = "Running integration..."
        print("Starting integration process...")
        
        // Determine the source CSV file path.
        let sourceFilePath: String = {
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                return documentsDirectory.appendingPathComponent("source-sales.csv").path
            } else {
                return "/Users/e2mq173/Projects/dataframes/source-sales.csv"
            }
        }()
        
        let offsetValue = 0
        
        // Process integration for each month of 2024 & 2025.
        for year in 2024...2025 {
            for month in 1...12 {
                let formattedMonth = String(format: "%02d", month)
                let strProcessDate = "\(year)\(formattedMonth)"
                let fileURL = URL(fileURLWithPath: sourceFilePath)
                
                await SA01Integration.run(
                    fileURL: fileURL,
                    strProcessDate: strProcessDate,
                    fiscalOffset: offsetValue
                )
            }
        }
        
        statusMessage = "Integration completed."
        print("Integration process completed. Status updated to: \(statusMessage)")
    }
}

// MARK: - CSV Viewer (Paged)

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

// MARK: - Variables Browser

struct VariablesBrowserContentView: View {
    var body: some View {
        VariablesBrowserView(isPresented: .constant(true))
            .frame(minWidth: 800, minHeight: 600)
            .onAppear { print("VariablesBrowserContentView appeared.") }
    }
}

// MARK: - View Controller

struct ViewControllerContentView: View {
    var body: some View {
        // Although removed from the menu, this view remains available for other uses.
        ViewControllerWrapper()
            .frame(minWidth: 800, minHeight: 600)
            .onAppear { print("ViewControllerContentView appeared.") }
    }
}

// MARK: - Performance Charts

struct PerformanceChartsContentView: View {
    var body: some View {
        // Although removed from the menu, this view remains available for other uses.
        PerformanceChartsView()
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { print("PerformanceChartsContentView appeared.") }
    }
}
