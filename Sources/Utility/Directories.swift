import Foundation

public struct Directories {
    public static func recreateDirectory(at directory: URL) {
        do {
            if FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.removeItem(at: directory)
                LoggerManager.shared.logInfo("Removed existing directory at path: \(directory.path)")
            }
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            LoggerManager.shared.logInfo("Created directory at path: \(directory.path)")
        } catch {
            LoggerManager.shared.logError("Failed to recreate directory at path: \(directory.path). Error: \(error.localizedDescription)")
        }
    }
}
