//
//  SA01Execdute.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 9/3/2025.
//


import Foundation

public func SA01Execute(_ fileURL: URL,
                        strProcessDate: String,
                        fiscalOffset: Int) async throws -> URL {
    
    let fileName = fileURL.lastPathComponent
    print("Starting SA01 execution with file: \(fileName)")
    
    // Call the execute method using async/await, which returns the URL of the generated dataframe.csv.
    let dataframeURL = try await SA01.shared.execute(fileURL: fileURL,
                                                     strProcessDate: strProcessDate,
                                                     fiscalOffset: fiscalOffset)
    
    // Since the input is "YYYYMMDD", extract just the first 6 characters ("YYYYMM").
    let yearMonthString = String(strProcessDate.prefix(6))
    
    // Determine the destination directory (same as the source file).
    let destinationDirectory = fileURL.deletingLastPathComponent()
    
    // Build the new zip file name using the extracted year and month (YYYYMM.zip).
    let zipFileName = "\(yearMonthString).adf"
    let destinationZipURL = destinationDirectory.appendingPathComponent(zipFileName)
    
    // Prepare the file manager.
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: destinationZipURL.path) {
        try fileManager.removeItem(at: destinationZipURL)
    }
    
    // Zip the dataframe.csv file using the system zip command.
    // The "-j" option tells zip to junk the directory path and just store the file.
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    process.arguments = ["-j", destinationZipURL.path, dataframeURL.path]
    
    try process.run()
    process.waitUntilExit()
    
    // Check if the zip process was successful.
    if process.terminationStatus != 0 {
        throw NSError(domain: "ZipErrorDomain",
                      code: Int(process.terminationStatus),
                      userInfo: [NSLocalizedDescriptionKey: "Failed to create zip archive."])
    }
    
    print("Zipped dataframe.csv to \(destinationZipURL.path) with new filename: \(zipFileName)")
    
    print("\n")
    print("> Variables generated:")
    let variableGenerator = SAVariableGenerator()
    variableGenerator.printAllVariables()
    
    return destinationZipURL
}
