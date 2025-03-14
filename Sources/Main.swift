import SwiftUI
import Foundation

// MARK: - ViewController Wrapper


// MARK: - AppDelegate

// Create an AppDelegate to ensure the app quits when the last window is closed.
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}


// MARK: - Main App

@main
struct MyMacApp: App {
    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
    }
}
