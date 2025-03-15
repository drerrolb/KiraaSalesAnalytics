import Foundation
import TabularData

/// A structure representing a chunk file (if needed).
struct SA01ChunkFile {
    let chunkfileURL: URL
    var csvFileURL: URL?
    var analycalDataframe: DataFrame?
}

/// Utility function to parse date strings in YYYYMMDD format.
func parseDate(from dateString: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return dateFormatter.date(from: dateString)
}

/// Processes the DataFrame by splitting it into chunks. Each chunk is written to disk
/// and then processed in parallel (using GCD) rather than sequentially.
func SA01Chunk(dataframe: DataFrame,
               strProcessDate: String,
               fiscalOffset: Int) throws -> [URL] {
    
    // Define CSV header and keys.
    let utf8BOM = "\u{FEFF}"
    let headerLine = """
    SA01DATE,SA01F01,SA01F02,SA01F03,SA01F04,SA01F05,SA01F06,SA01F07,SA01F08,SA01F09,SA01F10,\
    SA01F11,SA01F12,SA01F13,SA01F14,SA01F15,SA01F16,SA01F17,SA01F18,SA01F19,SA01F20,SA01F21,\
    SA01F22,SA01F23,SA01F24,SA01F25,SA01F26,SA01F27,SA01F28,SA01F29,SA01F30,SA01F31,SA01F32,\
    SA01F33,SA01F34,SA01F35,SA01F36,SA01F37,SA01F38,SA01F39,SA01F40,SA01F41,SA01F42,SA01F43,\
    SA01F44,SA01F45,SA01F46,SA01F47,SA01F48,SA01F49,SA01F50,SA01F51,SA01F52,SA01F53,SA01F54,\
    SA01F55,SA01F56,SA01F57,SA01F58,SA01F59,SA01F60,SA01F61,SA01F62,SA01F63,SA01F64,SA01F65,\
    SA01F66,SA01F67,SA01F68,SA01F69,SA01F70,SA01F71,SA01F72,SA01F73,SA01F74,SA01F75,SA01F76,\
    SA01F77,SA01F78,SA01F79,SA01F80,SA01F81,SA01F82,SA01F83,SA01F84,SA01F85,SA01F86,SA01F87,\
    SA01F88,SA01F89,SA01F90,SA01F91,SA01F92,SA01F93,SA01F94,SA01F95,SA01F96,SA01F97,SA01F98,\
    SA01F99,SA01MEASURE,SA01VALUE
    """
    let headerKeys = headerLine.split(separator: ",").map { String($0) }
    
    // Create a safe copy of the DataFrame rows.
    let safeRows: [[String: String]] = Array(dataframe.rows).map { row in
        var safeRow: [String: String] = [:]
        for key in headerKeys {
            safeRow[key] = row[key].map { "\($0)" } ?? ""
        }
        return safeRow
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    
    let totalRows = safeRows.count
    let chunkSize = 5_000
    let numberOfChunks = (totalRows + chunkSize - 1) / chunkSize
    
    print(String(format: "Total rows: %8d, Chunk size: %8d, Number of chunks: %8d",
                 totalRows, chunkSize, numberOfChunks))
    
    // Process date parsing.
    let processDateFormatter = DateFormatter()
    processDateFormatter.dateFormat = "yyyyMM"
    processDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    guard let processDate = processDateFormatter.date(from: strProcessDate) else {
        throw NSError(domain: "SA01Chunk", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid process date"])
    }
    
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: processDate)
    guard let currentYear = dateComponents.year,
          let currentMonth = dateComponents.month,
          let currentDay = dateComponents.day else {
        throw NSError(domain: "SA01Chunk", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing date components"])
    }
    
    print("Current Year: \(currentYear), Current Month: \(currentMonth), Current Day: \(currentDay)")
    
    // Define boundaries.
    let startBoundaryComponents = DateComponents(year: currentYear - 2, month: 1, day: 1)
    guard let startOfLastCalendarYear = calendar.date(from: startBoundaryComponents) else {
        throw NSError(domain: "SA01Chunk", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create start date"])
    }
    print("Start of last calendar year: \(startOfLastCalendarYear)")
    
    let endBoundaryComponents = DateComponents(year: currentYear + 2, month: 12, day: 31)
    guard let endOfNextCalendarYear = calendar.date(from: endBoundaryComponents) else {
        throw NSError(domain: "SA01Chunk", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to compute end of subsequent calendar year"])
    }
    
    guard let startDateWithOffset = calendar.date(byAdding: .month, value: -fiscalOffset, to: startOfLastCalendarYear),
          let endDateWithOffset = calendar.date(byAdding: .month, value: fiscalOffset, to: endOfNextCalendarYear) else {
        throw NSError(domain: "SA01Chunk", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to compute date boundaries with fiscal offset"])
    }
    
    let startBoundary = dateFormatter.string(from: startDateWithOffset)
    let endBoundary = dateFormatter.string(from: endDateWithOffset)
    
    print("\nData Processing is within date boundaries of \(startBoundary) to \(endBoundary)\n")
    print("Splitting the source file into chunks and processing them in parallel.")
    
    // Prepare a concurrent queue and a dispatch group.
    let concurrentQueue = DispatchQueue(label: "com.SA01Chunk.concurrentQueue", attributes: .concurrent)
    let group = DispatchGroup()
    
    // Because we’ll append to this array across multiple threads, we need thread-safe access.
    var chunkFileURLs: [URL] = []
    let urlAccessLock = NSLock()
    
    for chunkIndex in 0..<numberOfChunks {
        // Enter the group before dispatching the block.
        group.enter()
        
        concurrentQueue.async {
            let chunkStartTime = Date()
            let startRow = chunkIndex * chunkSize
            let endRow = min(startRow + chunkSize, totalRows)
            let chunkStartString = dateFormatter.string(from: chunkStartTime)
            
            print(String(format: "Starting chunk %3d at %-23@: rows %8d to %8d",
                         chunkIndex, chunkStartString, startRow, endRow - 1))
            
            let chunkRows = Array(safeRows[startRow..<endRow])
            let validRows = chunkRows.filter { row in
                if let dateString = row["SA01DATE"],
                   let salesDate = parseDate(from: dateString) {
                    return salesDate >= startDateWithOffset && salesDate <= endDateWithOffset
                } else {
                    // Not in date range or invalid date. We skip it.
                    return false
                }
            }
            
            print(String(format: "Chunk %d: Processed %d rows; %d valid rows",
                         chunkIndex, chunkRows.count, validRows.count))
            
            // If there are no valid rows, we can simply exit.
            guard !validRows.isEmpty else {
                let chunkEndString = dateFormatter.string(from: Date())
                print("\nFinished chunk \(chunkIndex) at \(chunkEndString): No valid rows to process.")
                group.leave()
                return
            }
            
            // Create the conform directory if needed.
            let conformDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("conform")
            try? FileManager.default.createDirectory(at: conformDirectory, withIntermediateDirectories: true)
            let conformIndex = String(format: "%06d", chunkIndex)
            let confirmFilename = "\(conformIndex).csv"
            let chunkFileURL = conformDirectory.appendingPathComponent(confirmFilename)
            
            // Write header and rows to CSV.
            var chunkCSV = utf8BOM + headerLine + "\n"
            for row in validRows {
                let rowString = headerKeys.map { key -> String in
                    var value = row[key] ?? ""
                    if value.isEmpty { value = "[None]" }
                    // Escape quotes.
                    value = value.replacingOccurrences(of: "\"", with: "\"\"")
                    // Sanitize: allow letters, numbers, whitespace, and select punctuation.
                    value = value.filter {
                        $0.isLetter || $0.isNumber || $0.isWhitespace ||
                        $0 == "." || $0 == "," || $0 == "-" || $0 == "_"
                    }
                    // Ensure quotes around the entire cell.
                    if !value.hasPrefix("\"") || !value.hasSuffix("\"") {
                        value = "\"\(value)\""
                    }
                    return value
                }.joined(separator: ",")
                chunkCSV += rowString + "\n"
            }
            
            do {
                try chunkCSV.write(to: chunkFileURL, atomically: true, encoding: .utf8)
                print("\n Chunk \(chunkIndex): CSV file written at \(chunkFileURL.path)")
            } catch {
                print("\n* Error writing chunk \(chunkIndex) file \(chunkFileURL): \(error.localizedDescription)")
                // Even if writing fails, we still leave the group for this chunk.
                group.leave()
                return
            }
            
            // Process the chunk file
            let chunkFile = SA01ChunkFile(chunkfileURL: chunkFileURL)
            do {
                // Example synchronous call:
                _ = try processChunkFile(chunkFile, chunkId: chunkIndex,
                                         strProcessDate: strProcessDate,
                                         fiscalOffset: fiscalOffset)
                
                // Append the chunk file URL in a thread-safe way.
                urlAccessLock.lock()
                chunkFileURLs.append(chunkFileURL)
                urlAccessLock.unlock()
                
                let chunkEndString = dateFormatter.string(from: Date())
                print("\nFinished processing chunk \(chunkIndex) at \(chunkEndString): \(chunkFileURL.path)")
            } catch {
                print("Error processing chunk \(chunkIndex): \(error.localizedDescription)")
            }
            
            // Signal that this chunk is complete.
            group.leave()
        }
    }
    
    // Wait for all chunks to finish processing before returning.
    group.wait()
    
    let completionTimeString = dateFormatter.string(from: Date())
    print(String(format: "Chunk file completion at %@: Total chunks: %d",
                 completionTimeString, chunkFileURLs.count))
    print("All chunks have finished processing. A complete set of DataFrame files exists in the chunk directory.")
    
    return chunkFileURLs
}
