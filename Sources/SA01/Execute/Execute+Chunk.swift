import Foundation
import TabularData  // Import the TabularData framework to work with DataFrames

public extension SA01 {
    
    func loadAndChunk(fileURL: URL,
                      strProcessDate: String,
                      fiscalOffset: Int) async throws {
        
        // Process parameters.
        let fileName = fileURL.lastPathComponent
        
        LoggerManager.shared.logInfo("Commenced Source File Load Process: \(fileName)")
        
        // Define directories needed for processing.
        let directories = [
            FileManager.default.temporaryDirectory.appendingPathComponent("chunk"),
            FileManager.default.temporaryDirectory.appendingPathComponent("dataframe"),
            FileManager.default.temporaryDirectory.appendingPathComponent("conform")
        ]
        
        directories.forEach { directory in
            Directories.recreateDirectory(at: directory)
            LoggerManager.shared.logInfo("Directory at path: \(directory.path)")
            print("> Created directory at path: \(directory.path)")
        }
        
        // Describe the loaded file.
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            let creationDate = attributes[.creationDate] as? Date ?? Date()
            let modificationDate = attributes[.modificationDate] as? Date ?? Date()
            let fileSize = attributes[.size] as? UInt64 ?? 0
            let fileSizeMB = Double(fileSize) / (1024 * 1024)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let creationDateString = dateFormatter.string(from: creationDate)
            let modificationDateString = dateFormatter.string(from: modificationDate)
            
            print("\nLoading source file with the following details:")
            print("> Name      : \(fileURL.lastPathComponent)")
            print("> Size      : \(String(format: "%.2f MB", fileSizeMB))")
            print("> Created   : \(creationDateString)")
            print("> Modified  : \(modificationDateString)")
            print("\n")
        }
        
        print("\n")
        print("Please wait while source file is loaded into memory...")
        print("\n")
        // Load the CSV file into a DataFrame.
        let dataframe: DataFrame
        do {
            dataframe = try DataFrame(contentsOfCSVFile: fileURL)
            let rowCount = dataframe.shape.rows
            let columnCount = dataframe.shape.columns
            print("> Loaded CSV into DataFrame with \(rowCount) rows and \(columnCount) columns.")
        } catch {
            print("> Error loading CSV into DataFrame: \(error.localizedDescription)")
            throw error
        }
        
        // Execute Chunking
        
        _ = try SA01Chunk(dataframe: dataframe,
                                    strProcessDate: strProcessDate,
                                    fiscalOffset: fiscalOffset)

        
        
    }
}
