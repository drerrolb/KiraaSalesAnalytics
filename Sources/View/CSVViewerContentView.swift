import SwiftUI

/// Example CSVViewer content
struct xxxxCSVViewerContentView: View {
    @State private var pageTimer: Timer? = nil
    @State private var currentPage = 1
    @State private var totalRows = 217212  // Example
    
    var body: some View {
        VStack {
            Text("CSV Viewer Content")
                .font(.headline)
                .padding()
            Text("Total rows: \(totalRows)")
            Text("Current page: \(currentPage)")
            HStack {
                Button("Previous Page") {
                    moveToPreviousPage()
                }
                Button("Next Page") {
                    moveToNextPage()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            print("CSVViewerContentView appeared.")
            startTimer()
        }
        .onDisappear {
            print("CSVViewerContentView disappearing.")
            stopTimer()
            print("stopTimer() has completed for CSVViewerContentView.")
        }
    }
    
    // MARK: - Timer Handling
    
    private func startTimer() {
        print("startTimer() called in CSVViewerContentView.")
        pageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            // The timer callback might not be on the main actor,
            // so we dispatch UI updates via a Task on the main actor.
            Task { @MainActor in
                logTimerFired()
                await moveToNextPage()
            }
        }
        
        if let timer = pageTimer {
            print("pageTimer created: \(timer). Will fire first at: \(timer.fireDate)")
        } else {
            print("ERROR: pageTimer failed to create!")
        }
    }
    
    private func stopTimer() {
        print("stopTimer() called in CSVViewerContentView.")
        pageTimer?.invalidate()
        pageTimer = nil
        print("pageTimer invalidated and set to nil.")
    }
    
    // MARK: - Main-Actor Methods
    
    @MainActor
    private func logTimerFired() {
        // Accessing main-actor state like pageTimer is now safe.
        print("Timer fired for CSVViewerContentView. pageTimer: \(String(describing: pageTimer))")
        print("Are we on the main thread? \(Thread.isMainThread)")
    }

    @MainActor
    private func moveToNextPage() {
        print("moveToNextPage() called. Current page = \(currentPage). Incrementing now.")
        currentPage += 1
        print("Moved to next page: \(currentPage)")
    }
    
    @MainActor
    private func moveToPreviousPage() {
        print("moveToPreviousPage() called. Current page = \(currentPage). Decrementing now.")
        currentPage = max(1, currentPage - 1)
        print("Moved to previous page: \(currentPage)")
    }
}
