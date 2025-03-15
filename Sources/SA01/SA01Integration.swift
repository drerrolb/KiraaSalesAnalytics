import Foundation

public struct SA01Integration {
    public static func run(fileURL: URL, strProcessDate: String, fiscalOffset: Int) async {
        // Text art to indicate integration name.
        let textArt = """
        ░██████╗░█████╗░░█████╗░░░███╗░░
        ██╔════╝██╔══██╗██╔══██╗░████║░░
        ╚█████╗░███████║██║░░██║██╔██║░░
        ░╚═══██╗██╔══██║██║░░██║╚═╝██║░░
        ██████╔╝██║░░██║╚█████╔╝███████╗
        ╚═════╝░╚═╝░░╚═╝░╚════╝░╚══════╝
        """
        
        // Log welcome message and text art.
        await MainActor.run {
            LoggerViewModel.shared.log("Welcome to Kiraa Sales Analytics!")
            LoggerViewModel.shared.log("")
            LoggerViewModel.shared.log(textArt)
            LoggerViewModel.shared.log("")
        }
        
        // Step 1: Validate the source file.
        await MainActor.run {
            LoggerViewModel.shared.log("Step 1.0")
            LoggerViewModel.shared.log("Validating that the CSV file is found at the specified location.")
        }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            await MainActor.run {
                LoggerViewModel.shared.log("> CSV file found at \(fileURL.path)")
            }
        } else {
            await MainActor.run {
                LoggerViewModel.shared.log("> CSV file not found at \(fileURL.path)")
            }
        }
        
        await MainActor.run {
            LoggerViewModel.shared.log("")
        }
        
        let parametersOutput = """
        Starting execution of Kiraa Sales Analytics Integration with the following parameters:
        > Source File:   \(fileURL.path)
        > Model:         SA01
        > Process Date:  \(strProcessDate)
        > Fiscal Offset: \(fiscalOffset)
        """
        await MainActor.run {
            LoggerViewModel.shared.log(parametersOutput)
        }
        
        // Record the start time.
        let startTime = Date()
        
        do {
            // Execute the integration using async/await.
            let finalMessage = try await SA01Execute(fileURL,
                                                     strProcessDate: strProcessDate,
                                                     fiscalOffset: fiscalOffset)
            
            // Record the end time and compute the execution duration.
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)
            let formattedTime = formatTimeInterval(executionTime)
            
            await MainActor.run {
                LoggerViewModel.shared.log("Execution completed successfully: \(finalMessage)")
                LoggerViewModel.shared.log("Final Status: OK")
                LoggerViewModel.shared.log("Execution Time: \(formattedTime)")
            }
        } catch {
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)
            let formattedTime = formatTimeInterval(executionTime)
            
            await MainActor.run {
                LoggerViewModel.shared.log("Execution failed: \(error.localizedDescription)")
                LoggerViewModel.shared.log("Execution Time: \(formattedTime)")
            }
        }
    }
}
