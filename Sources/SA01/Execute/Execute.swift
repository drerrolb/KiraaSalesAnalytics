import Foundation
import TabularData  // Import the TabularData framework to work with DataFrames

public extension SA01 {
    
    func execute(fileURL: URL,
                 strProcessDate: String,
                 fiscalOffset: Int) async throws -> URL {
        
        // Process parameters.
        let fileName = fileURL.lastPathComponent

        // ===================================================================================
        // STEP 2.1: SETUP & LOGGING
        // ===================================================================================
        
        // Define directories needed for processing.
        let directories = [
            FileManager.default.temporaryDirectory.appendingPathComponent("chunk"),
            FileManager.default.temporaryDirectory.appendingPathComponent("dataframe"),
            FileManager.default.temporaryDirectory.appendingPathComponent("conform")
        ]
        
        directories.forEach { directory in
            Directories.recreateDirectory(at: directory)
            print("> Created directory at path: \(directory.path)")
        }
        
        await LoggerViewModel.shared.log("Execution started for \(strProcessDate) for \(fileName)")
        // ===================================================================================
        // STEP 2.3: DESCRIBE THE FILE
        // ===================================================================================
        
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
        
        // ===================================================================================
        // STEP 2.4: LOAD CSV INTO DATAFRAME
        // ===================================================================================
        
        await LoggerViewModel.shared.log("Please wait while source file is loaded into memory...")
        
        let dataframe: DataFrame
        do {
            dataframe = try DataFrame(contentsOfCSVFile: fileURL)
            let rowCount = dataframe.shape.rows
            let columnCount = dataframe.shape.columns
            await LoggerViewModel.shared.log("> Loaded CSV into DataFrame with \(rowCount) rows and \(columnCount) columns.")
            
        } catch {
            print("> Error loading CSV into DataFrame: \(error.localizedDescription)")
            throw error
        }
        
        // ===================================================================================
        // STEP 3: PROCESS CHUNKS
        // ===================================================================================
        
        // Execute chunking process using async/await.
        let chunkURLs = try SA01Chunk(dataframe: dataframe,
                                            strProcessDate: strProcessDate,
                                            fiscalOffset: fiscalOffset)
        
        await LoggerViewModel.shared.log("Chunking complete. Chunk URLs: \(chunkURLs)")

        // now generate the final analytical dataframe
        let analyticalDataframeURL = try generateAnalyticalDataframe()
        
        await LoggerViewModel.shared.log("Analytical DataFrame generated at: \(analyticalDataframeURL)")
        
        return analyticalDataframeURL
    }
}
