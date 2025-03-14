import SwiftUI
import AppKit

/// 1) Mark the function as @MainActor so all NSWindow calls happen on the main thread.
@MainActor
func openIntegrationWindow() {
    // Creating and configuring an NSWindow is main actor-isolated.
    let newWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
        styleMask: [.titled, .closable, .resizable],
        backing: .buffered,
        defer: false
    )
    newWindow.center()
    newWindow.title = "Integration"
    newWindow.contentView = NSHostingView(rootView: IntegrationView())
    newWindow.makeKeyAndOrderFront(nil)
    print("IntegrationView window opened.")
}

// MARK: - IntegrationView SwiftUI definition
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
    
    // This function simulates your asynchronous integration work.
    @MainActor
    func runIntegration() async {
        statusMessage = "Running integration..."
        print("Starting integration process...")
        // Simulate some asynchronous work.
        try? await Task.sleep(nanoseconds: 500_000_000)
        statusMessage = "Integration completed."
        print("Integration process completed. Status updated to: \(statusMessage)")
    }
}
