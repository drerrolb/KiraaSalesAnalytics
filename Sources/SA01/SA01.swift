//
//  SA01.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 21/2/2025.
//

import Foundation
import os.log


// NOTE: The following types (Integration, GoogleCloudStorageClient, SA01kwargs, etc.)
// are assumed to be defined elsewhere or imported as needed.

public final class SA01: @unchecked Sendable {
    
    // MARK: - Properties
    public static let shared = SA01()
    
    public let currentYear: Int
    public let currentMonth: Int
    
    // Dispatch queues for concurrent processing.
    public let processingQueue = DispatchQueue(label: "SalesAnalytics.processingQueue", attributes: .concurrent)
    public let rowAnalyticsQueue = DispatchQueue(label: "SalesAnalytics.rowAnalyticsQueue", attributes: .concurrent)
    
    // MARK: - Initializer
    public init() {
        let calendar = Calendar.current
        self.currentYear = calendar.component(.year, from: Date())
        self.currentMonth = calendar.component(.month, from: Date())
    }
    
    // MARK: - Other Functionalities
    
    /// Converts chunk analysis data to a CSV-formatted string.
    public func convertToCSV(chunkAnalysis: [String: [String: Any]]) -> String {
        LoggerManager.shared.logInfo("Starting CSV conversion for chunk analysis data.")
        print(">>> Starting CSV conversion for chunk analysis data.")
        var csvString = ""
        if let firstEntry = chunkAnalysis.first?.value {
            let headers = firstEntry.keys.sorted()
            csvString += headers.joined(separator: ",") + "\n"
            LoggerManager.shared.logInfo("CSV headers: \(headers.joined(separator: ", "))")
            print(">>> CSV headers: \(headers.joined(separator: ", "))")
        }
        for (rowKey, analysis) in chunkAnalysis {
            let headers = analysis.keys.sorted()
            let rowString = headers.map { header in
                if let value = analysis[header] {
                    return "\"\(value)\""
                }
                return "\"\""
            }.joined(separator: ",")
            LoggerManager.shared.logInfo("Row \(rowKey) CSV: \(rowString)")
            print(">>> Row \(rowKey) CSV: \(rowString)")
            csvString += rowString + "\n"
        }
        LoggerManager.shared.logInfo("Completed CSV conversion.")
        print(">>> Completed CSV conversion.")
        return csvString
    }
    
    /// Saves the CSV data to a file and optionally uploads it.
    public func saveCSVToFile(data: String,
                              guid: String,
                              chunkIndex: Int,
                              bucketName: String,
                              region: String,
                              completion: @escaping (Result<URL, Error>) -> Void) {
        LoggerManager.shared.logInfo("Starting saveCSVToFile with guid: \(guid), chunkIndex: \(chunkIndex), bucketName: \(bucketName), region: \(region)")
        print(">>> Starting saveCSVToFile with guid: \(guid), chunkIndex: \(chunkIndex), bucketName: \(bucketName), region: \(region)")
        
        // Create a file URL for the CSV file.
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "\(guid)_chunk_\(chunkIndex).csv"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL, atomically: true, encoding: .utf8)
            LoggerManager.shared.logInfo("CSV file successfully saved at: \(fileURL.path)")
            print(">>> CSV file successfully saved at: \(fileURL.path)")
            // TODO: Optionally implement file upload.
            completion(.success(fileURL))
        } catch {
            LoggerManager.shared.logError("Error saving CSV file: \(error.localizedDescription)")
            print(">>> Error saving CSV file: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
}


