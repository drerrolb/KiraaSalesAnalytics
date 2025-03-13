import SwiftUI
import Foundation

// MARK: - ViewController Wrapper

// Wrap your existing NSViewController in a SwiftUI-compatible view.
struct ViewControllerWrapper: NSViewControllerRepresentable {
    @Binding var isPresented: Bool

    func makeNSViewController(context: Context) -> ViewController {
        let vc = ViewController()
        // When the NSViewController is told to close, update the binding.
        vc.dismissCallback = {
            isPresented = false
        }
        return vc
    }
    
    func updateNSViewController(_ nsViewController: ViewController, context: Context) {
        // Update the view controller if needed.
    }
}

// MARK: - AppDelegate

// Create an AppDelegate to ensure the app quits when the last window is closed.
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}


// MARK: - Main App

@main
struct KiraaSalesAnalyticsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
