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
        
        print("\nStep 2.1")
        print("Loading the \(fileName) file and splitting into chunks for streamlined processing.")
        
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
        
        print ("Please wait while source file is loaded into memory...")
        print ("\n")
        
        
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
        
        // ===================================================================================
        // STEP 3: PROCESS CHUNKS
        // ===================================================================================
        
        // Execute chunking process using async/await.
        let chunkURLs = try SA01Chunk(dataframe: dataframe,
                                            strProcessDate: strProcessDate,
                                            fiscalOffset: fiscalOffset)
        
        print("Chunking complete. Chunk URLs: \(chunkURLs)")
        print("\n")

        // now generate the final analytical dataframe
        let analyticalDataframeURL = try generateAnalyticalDataframe()
        print("Analytical DataFrame generated at: \(analyticalDataframeURL)")
        print("\n")
        
        return analyticalDataframeURL
    }
}
