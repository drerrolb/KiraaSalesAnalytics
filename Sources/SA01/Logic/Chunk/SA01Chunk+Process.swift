import Foundation
import TabularData

func processChunkFile(_ chunk: SA01ChunkFile, chunkId: Int, strProcessDate: String, fiscalOffset: Int ) throws -> DataFrame {
    // Use csvFileURL if available; otherwise, fallback to chunkfileURL.
    let csvURL = chunk.csvFileURL ?? chunk.chunkfileURL

    // Configure CSV reading options.
    let csvOptions = CSVReadingOptions(hasHeaderRow: true, delimiter: ",")

    // Load the CSV file into a DataFrame synchronously.
    var SA01dataFrame: DataFrame?
    do {
        SA01dataFrame = try DataFrame(contentsOfCSVFile: csvURL, options: csvOptions)
    } catch {
        let errorMessage = "Failed to load DataFrame from CSV file at \(csvURL). Error: \(error)"
        print("> ERROR: \(errorMessage)")
        throw NSError(domain: "ProcessChunkFile", code: 1000, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }

    guard let loadedDataFrame = SA01dataFrame, loadedDataFrame.rows.count > 0 else {
        let errorMessage = "Loaded DataFrame is empty. File: \(csvURL)"
        print("> ERROR: \(errorMessage)")
        throw NSError(domain: "ProcessChunkFile", code: 1001, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }

    // Modify the DataFrame columns.
    var modifiedDataFrame = loadedDataFrame
    modifiedDataFrame["SA01DATE"] = modifiedDataFrame["SA01DATE"].map { value in
        guard let unwrappedValue = value else { return "" }
        return "\(unwrappedValue)"
    }
    modifiedDataFrame["SA01VALUE"] = modifiedDataFrame["SA01VALUE"].map { value in
        guard let unwrappedValue = value else { return 0.0 }
        let stringValue = "\(unwrappedValue)"
        return Double(stringValue) ?? 0.0
    }

    // undertake analyyss
    let analysisDataframe = SA01Analysis(dataframe: modifiedDataFrame,
                                         strProcessDate: strProcessDate,
                                         fiscalOffset: fiscalOffset,
                                         chunkId: chunkId)

    // Prepare file saving parameters.
    let chunkFilename = String(format: "%06d.csv", chunkId)
    let chunkDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("chunk")
    try? FileManager.default.createDirectory(at: chunkDirectory, withIntermediateDirectories: true)
    let fullFilePath = chunkDirectory.appendingPathComponent(chunkFilename).path

    // Save the analytical DataFrame to disk synchronously.
    do {
        try saveDataFrameToCSV(dataFrame: analysisDataframe, filePath: fullFilePath)
    } catch {
        let errorMessage = "Failed to save DataFrame to CSV file at \(fullFilePath). Error: \(error)"
        print("> ERROR: \(errorMessage)")
        throw NSError(domain: "ProcessChunkFile", code: 1002, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }

    print("\nSuccessfully saved DataFrame with \(analysisDataframe.rows.count) rows to file: \(fullFilePath) (filename: \(chunkFilename))")
    return analysisDataframe
}
