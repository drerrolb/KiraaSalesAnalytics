import SwiftUI
import Foundation

// MARK: - Logger View Model
@MainActor
class LoggerViewModel: ObservableObject {
    static let shared = LoggerViewModel()
    
    @Published var messages: [String] = []
    
    func log(_ message: String) {
        messages.append(message)
    }
}

// MARK: - IntegrationContentView
struct IntegrationContentView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Editable defaults.
    @State private var filePath: String = "/Users/e2mq173/Documents/source-sales.csv"
    @State private var startDate: Date = Date()  // Defaults to current date.
    @State private var endDate: Date = Date()    // Defaults to current date.
    @State private var fiscalOffset: Int = 6
    
    // UI feedback.
    @State private var isRunning = false
    @State private var resultText = ""
    
    // Shared logger.
    @ObservedObject var logger = LoggerViewModel.shared
    
    // Helper: Format a Date as "YYYYMM"
    func formatDateToYYYYMM(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        return formatter.string(from: date)
    }
    
    // Helper: Generate an array of month strings (YYYYMM) between start and end (inclusive).
    func monthsBetween(start: Date, end: Date) -> [String] {
        var months: [String] = []
        var current = start
        let calendar = Calendar.current
        while current <= end {
            months.append(formatDateToYYYYMM(current))
            if let next = calendar.date(byAdding: .month, value: 1, to: current) {
                current = next
            } else {
                break
            }
        }
        return months
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Integration")
                .font(.title)
                .padding(.top)
            
            // File Path input.
            HStack {
                Text("File Path:")
                    .frame(width: 120, alignment: .leading)
                TextField("File Path", text: $filePath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Start and End Date Pickers side by side.
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Start Date:")
                    DatePicker("", selection: $startDate, displayedComponents: [.date])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                }
                VStack(alignment: .leading) {
                    Text("End Date:")
                    DatePicker("", selection: $endDate, displayedComponents: [.date])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                }
            }
            .padding(.horizontal)
            
            // Fiscal Offset input as a dropdown.
            HStack {
                Text("Fiscal Offset:")
                    .frame(width: 120, alignment: .leading)
                Picker("Fiscal Offset", selection: $fiscalOffset) {
                    ForEach(0...11, id: \.self) { offset in
                        Text("\(offset)").tag(offset)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.horizontal)
            
            // Run Integration Button.
            Button("Run Integration") {
                isRunning = true
                resultText = "Running integration..."
                Task {
                    await runIntegration()
                }
            }
            .disabled(isRunning)
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            
            // Display result message.
            if !resultText.isEmpty {
                Text(resultText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            
            // Terminal-style log display.
            Text("Logs:")
                .font(.headline)
                .padding(.top)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(logger.messages, id: \.self) { message in
                        Text(message)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 150)
            .background(Color.black)
            .cornerRadius(8)
            .padding(.horizontal)
            
            Spacer()
            
            // Close Button.
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        // Flexible frame for full-screen support.
        .frame(minWidth: 500, idealWidth: 800, maxWidth: .infinity,
               minHeight: 600, idealHeight: 800, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Integration Runner
    func runIntegration() async {
        defer { isRunning = false }
        let fileURL = URL(fileURLWithPath: filePath)
        
        // Generate month strings in YYYYMM format.
        let months = monthsBetween(start: startDate, end: endDate)
        logger.log("Starting integration for months: \(months.joined(separator: ", "))")
        logger.log("Fiscal Offset: \(fiscalOffset)")
        
        // Iterate through each month and run the integration sequentially.
        for month in months {
            logger.log("Starting integration for month: \(month)")
            await SA01Integration.run(fileURL: fileURL,
                                      strProcessDate: month,
                                      fiscalOffset: fiscalOffset)
            logger.log("Completed integration for month: \(month)")
        }
        resultText = "Integration complete for all months. Check logs for details."
    }
}
