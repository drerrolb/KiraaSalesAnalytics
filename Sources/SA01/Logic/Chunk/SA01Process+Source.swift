import Foundation
import TabularData

// Allow DataFrame to be used across concurrency boundaries.
extension DataFrame: @unchecked @retroactive Sendable {}


func prossssscessLoadedData(data: [URL],
                        strProcessDate: String,
                       fiscalOffset: Int) async -> String {
    // Convert URLs into SA01ChunkFile objects.
    let chunks = data.map { SA01ChunkFile(chunkfileURL: $0) }
    let progressTracker = ProgressTracker()
    await progressTracker.updateProgress(to: 0.10)
    
    // Process each chunk concurrently.
    let groupResults: [(Int, Result<DataFrame, Error>)] = await withTaskGroup(of: (Int, Result<DataFrame, Error>).self) { group in
        for (index, chunk) in chunks.enumerated() {
            group.addTask { @Sendable in
                do {
                    let df = try await processChunkFile(chunk, chunkId: index,
                                                        strProcessDate: strProcessDate,
                                                        fiscalOffset: fiscalOffset)
                    print("\nChunk \(index) processed successfully.")
                    return (index, .success(df))
                } catch {
                    return (index, .failure(error))
                }
            }
        }
        
        var results: [(Int, Result<DataFrame, Error>)] = []
        var processedCount = 0
        for await result in group {
            processedCount += 1
            let progress = 0.10 + 0.80 * Double(processedCount) / Double(chunks.count)
            await progressTracker.updateProgress(to: progress)
            results.append(result)
            print("> Processed chunk \(result.0)")
        }
        return results
    }
    
    // Collect successful DataFrames and error messages.
    var processedChunks: [DataFrame] = []
    var errors: [String] = []
    for (_, result) in groupResults {
        switch result {
        case .success(let df):
            processedChunks.append(df)
        case .failure(let error):
            errors.append("Error processing chunk: \(error.localizedDescription)")
        }
    }
    
    var summary = "Processed \(processedChunks.count) DataFrame chunks"
    if !errors.isEmpty {
        summary += " with \(errors.count) errors: \(errors.joined(separator: ", "))"
    }
    

    
    await progressTracker.updateProgress(to: 1.0)
    return summary
}
