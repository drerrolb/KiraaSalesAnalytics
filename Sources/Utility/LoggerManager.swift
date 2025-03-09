import Foundation
import os.log

public struct LoggerManager: Sendable {
    public static let shared = LoggerManager()
    
    private let logger = Logger(subsystem: "com.example.SalesAnalytics", category: "SA01")
    
    public func logInfo(_ message: String,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        logger.info("\(message, privacy: .public) [\((file as NSString).lastPathComponent):\(line) \(function)]")
    }
    
    public func logError(_ message: String,
                         file: String = #file,
                         function: String = #function,
                         line: Int = #line) {
        logger.error("\(message, privacy: .public) [\((file as NSString).lastPathComponent):\(line) \(function)]")
    }
}

