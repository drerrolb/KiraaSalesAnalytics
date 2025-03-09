import Foundation

/// Merges all CSV files in the "chunk" directory into a single CSV file named "dataframe.csv"
/// inside a "dataframe" directory, and returns its URL.
func generateAnalyticalDataframe() throws -> URL {
    // 1. Identify the directory with chunked CSVs
    let chunkDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("chunk")
    
    // 2. Gather CSV files from the chunk directory
    let csvFiles = try FileManager.default.contentsOfDirectory(at: chunkDirectory,
                                                               includingPropertiesForKeys: nil)
        .filter { $0.pathExtension.lowercased() == "csv" }
    
    guard !csvFiles.isEmpty else {
        throw NSError(domain: "NoCSVFilesFound", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "No .csv files were found in \(chunkDirectory.path)"
        ])
    }
    
    // 3. Define the output directory (dataframe directory) and ensure it exists.
    let dataframeDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("dataframe", isDirectory: true)
    if !FileManager.default.fileExists(atPath: dataframeDirectory.path) {
        try FileManager.default.createDirectory(at: dataframeDirectory, withIntermediateDirectories: true)
    }
    
    // 4. Define the output file URL for the merged CSV file.
    let outputFileURL = dataframeDirectory.appendingPathComponent("dataframe.csv")
    
    // 5. Open an output stream to write to the merged CSV file
    guard let outputStream = OutputStream(url: outputFileURL, append: false) else {
        throw NSError(domain: "OutputStreamError", code: -2, userInfo: [
            NSLocalizedDescriptionKey: "Could not open output stream for file: \(outputFileURL.path)"
        ])
    }
    outputStream.open()
    defer { outputStream.close() }
    
    var isHeaderWritten = false
    
    // 6. Process each CSV file (using sorted order for consistency)
    for csvFileURL in csvFiles.sorted(by: { $0.path < $1.path }) {
        // Read the content of the CSV file
        let csvContent = try String(contentsOf: csvFileURL, encoding: .utf8)
        var lines = csvContent.components(separatedBy: .newlines)
        // Remove any empty lines
        lines.removeAll { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !lines.isEmpty else { continue }
        
        // Write the header only once from the first file
        if !isHeaderWritten {
            let headerLine = lines[0]
            writeToStream(outputStream, string: headerLine + "\n")
            isHeaderWritten = true
        }
        
        // Convert the slice to an array for type consistency
        let dataLines = isHeaderWritten ? Array(lines.dropFirst()) : lines
        for line in dataLines {
            writeToStream(outputStream, string: line + "\n")
        }
    }
    
    print("Merged CSV written to: \(outputFileURL.path)")
    return outputFileURL
}

/// Helper function to write a string to an OutputStream
func writeToStream(_ stream: OutputStream, string: String) {
    guard let data = string.data(using: .utf8) else { return }
    data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
        if let pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) {
            stream.write(pointer, maxLength: data.count)
        }
    }
}
