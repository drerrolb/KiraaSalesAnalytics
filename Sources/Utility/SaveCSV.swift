import Foundation
import TabularData

public func saveDataFrameToCSV(dataFrame: DataFrame, filePath: String) {
    // Local helper: Escapes a CSV field by doubling internal quotes and wrapping it in quotes.
    func escapeCSVField(_ field: String) -> String {
        let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedField)\""
    }
    
    var csvString = ""
    
    // Extract header names from the DataFrame's columns.
    let headers = dataFrame.columns.map { $0.name }
    // Fully quote each header for the CSV.
    let quotedHeaders = headers.map { escapeCSVField($0) }
    
    // Build the CSV header line.
    csvString.append(quotedHeaders.joined(separator: ","))
    csvString.append("\n")
    
    // Write each row using the extracted header names.
    for row in dataFrame.rows {
        let rowValues: [String] = headers.map { colName in
            if let value = row[colName] {
                // If the value is a Double, check for 0 and integer values.
                if let doubleValue = value as? Double {
                    if doubleValue == 0 {
                        // Return an empty string for a zero value.
                        return ""
                    } else if doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
                        return String(Int(doubleValue))
                    } else {
                        return String(doubleValue)
                    }
                } else {
                    // Otherwise, output the string fully quoted.
                    return escapeCSVField(String(describing: value))
                }
            } else {
                return escapeCSVField("")
            }
        }
        csvString.append(rowValues.joined(separator: ","))
        csvString.append("\n")
    }
    
    do {
        try csvString.write(toFile: filePath, atomically: true, encoding: .utf8)
        print("\n> CSV file saved successfully at \(filePath)")
    } catch {
        print("\n> Error saving CSV file: \(error)")
    }
}
