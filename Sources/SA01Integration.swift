//
//  SA01Integration.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 24/2/2025.
//


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
        
        // Print welcome message and text art.
        print("Welcome to Kiraa Sales Analytics!")
        print("\n")
        print(textArt)
        print("\n")
        
        // Step 1: Validate the source file.
        print("Step 1.0")
        print("Validating that the CSV file is found at the specified location.")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            LoggerManager.shared.logInfo("CSV file found at \(fileURL.path)")
            print("> CSV file found at \(fileURL.path)")
        } else {
            LoggerManager.shared.logInfo("CSV file not found at \(fileURL.path)")
            print("> CSV file not found at \(fileURL.path)")
        }
        print("\n")
        
        
        let parametersOutput = """
        Starting execution of Kiraa Sales Analytics Integration with the following parameters:
        > Source File:   \(fileURL.path)
        > Model:         SA01
        > Process Date:  \(strProcessDate)
        > Fiscal Offset: \(fiscalOffset)
        """
        print(parametersOutput)
        


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
            
            LoggerManager.shared.logInfo("Execution completed successfully: \(finalMessage)")
            
            let finalMessage2 = "OK"
            
            printFinalBox(executionMessage: finalMessage2,
                          executionTime: formattedTime,
                          executionStatus: "Success")
        } catch {
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)
            let formattedTime = formatTimeInterval(executionTime)
            
            LoggerManager.shared.logError("Execution failed: \(error.localizedDescription)")
            printFinalBox(executionMessage: error.localizedDescription,
                          executionTime: formattedTime,
                          executionStatus: "Error")
        }
    }
}

