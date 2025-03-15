import SwiftUI
import Foundation

// MARK: - IntegrationContentView (Modal)
struct IntegrationContentView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Sample defaults that the user can edit in the UI.
    @State private var filePath: String = "/Users/e2mq173/Documents/source-sales.csv"
    @State private var processDate: String = "202502"
    @State private var fiscalOffset: Int = 0
    
    // State for controlling UI feedback.
    @State private var isRunning = false
    @State private var resultText = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Integration")
                .font(.title)
            
            // Labeled input for File Path.
            HStack {
                Text("File Path:")
                    .frame(width: 120, alignment: .leading)
                TextField("File Path", text: $filePath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Labeled input for Process Date.
            HStack {
                Text("Process Date:")
                    .frame(width: 120, alignment: .leading)
                TextField("YYYYMMDD", text: $processDate)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Labeled input for Fiscal Offset.
            HStack {
                Text("Fiscal Offset:")
                    .frame(width: 120, alignment: .leading)
                TextField("Fiscal Offset", value: $fiscalOffset, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Run button.
            Button("Run Integration") {
                isRunning = true
                resultText = "Running integration..."
                
                Task {
                    await runIntegration()
                }
            }
            .disabled(isRunning)
            .buttonStyle(.borderedProminent)
            
            // Display any output or results.
            if !resultText.isEmpty {
                Text(resultText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Close button.
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(width: 500, height: 400)
        .padding()
    }
    
    // MARK: - Integration Runner
    func runIntegration() async {
        defer { isRunning = false }
        
        let fileURL = URL(fileURLWithPath: filePath)
        
        // Call your async integration function.
        await SA01Integration.run(fileURL: fileURL,
                                  strProcessDate: processDate,
                                  fiscalOffset: fiscalOffset)
        
        // Update the UI with a result message.
        resultText = "Integration complete. Check logs for details."
    }
}
