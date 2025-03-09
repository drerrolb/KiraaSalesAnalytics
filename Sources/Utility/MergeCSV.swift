import Foundation
import TabularData

/// Merges CSVs, reads them into a single DataFrame (per-chunk),
/// reorders (or adds) columns so that the final DataFrame has
/// exactly the columns in the specified list, in that order.
/// Writes the final DataFrame to 'dataframe_final.csv' and returns its URL.
func createReorderedDataFrame(csvFiles: [URL]) throws -> URL {
    // 1) Output directory
    let dataframeDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("dataframe")
    try FileManager.default.createDirectory(at: dataframeDirectory,
                                            withIntermediateDirectories: true)

    // 2) Use the factory to get an empty DataFrame with all final columns
    var df = EmptyDataFrameFactory.create(rowCount: 0)

    // Extract the final column names from the columns just created
    let finalColumnNames = df.columns.map { $0.name }
    let allowedColumns = Set(finalColumnNames)

    // 3) CSV reading options
    //    If your CSV is comma-delimited with a header row, the default
    //    settings often suffice. But you can also do:
    var readingOptions = CSVReadingOptions()
    readingOptions.hasHeaderRow = true  // The default is true, but let's be explicit

    // 4) Read each CSV, reorder, and append
    for csvFile in csvFiles {
        // Read the CSV chunk
        let chunkDF = try DataFrame(contentsOfCSVFile: csvFile, options: readingOptions)

        // 4a) Check for unknown columns
        let actualColumns = chunkDF.columns.map { $0.name }
        let unknown = actualColumns.filter { !allowedColumns.contains($0) }
        if !unknown.isEmpty {
            let message = """
            Unknown columns in \(csvFile.lastPathComponent): \(unknown.joined(separator: ", "))
            Only columns allowed: \(finalColumnNames.joined(separator: ", "))
            """
            throw NSError(domain: "CSVColumnsError", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: message])
        }

        /*
        // 4b) Rebuild chunk in final order
        var reorderedChunk = DataFrame()
        let rowCount = chunkDF.rows.count
        
        for colName in finalColumnNames {
            if let existingCol = chunkDF.column(named: colName) {
                // If present, just append
                reorderedChunk.append(column: existingCol)
            } else {
                // Make an all-nil column by matching the "master" column type
                if let masterCol = df.column(named: colName) {
                    if masterCol is Column<String> {
                        let nilStrings = [String?](repeating: nil, count: rowCount)
                        // Use the older unlabeled init if your environment wants it:
                        var newCol = Column<String>(name:colName, contents: nilStrings)
                        reorderedChunk.append(column: newCol)
                    } else {
                        let nilDoubles = [Double?](repeating: nil, count: rowCount)
                        var newCol = Column<Double>(name: colName, contents: nilDoubles)
                        reorderedChunk.append(column: newCol)
                    }
                }
            }
        }
        */
        
        // 4c) Append chunk’s rows to the main DataFrame
        //df.append(rowsOf: reorderedChunk)
    }

    // 5) If no rows, bail
    guard df.rows.count > 0 else {
        throw NSError(domain: "CSVMergeError", code: -1,
                      userInfo: [NSLocalizedDescriptionKey:
                                 "No valid data found in the provided CSV files"])
    }

    // 6) Write final CSV
    let finalCSVFileURL = dataframeDirectory.appendingPathComponent("dataframe_final.csv")

    // If your older TabularData doesn't have CSVWritingOptions(delimiter:), just use default:
    try df.writeCSV(to: finalCSVFileURL)

    print("Wrote final CSV to \(finalCSVFileURL.path)")
    return finalCSVFileURL
}
