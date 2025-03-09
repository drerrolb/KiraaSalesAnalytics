import Foundation
import TabularData
import Metal

/// Generates an "analytical" DataFrame by selectively populating values
/// from `updatedDataFrame` based on time periods, years, measures, etc.
func generateAnalyticalDataFrame(updatedDataFrame: DataFrame,
                                 validTimePeriods: [(UInt32, [String])],
                                 validYears: [(UInt32, [String])],
                                 chunkId: Int) -> DataFrame
{
    //=============================================================================
    // PREPARE VARIABLES
    //=============================================================================
    
    // 2) Create a new "analytical" DataFrame with the same number of rows.
    let rowCount = updatedDataFrame.rows.count
    var analyticalDataFrame = EmptyDataFrameFactory.create(rowCount: rowCount)

    // 3) Verify that required columns exist in `updatedDataFrame`
    let existingColumnNames = updatedDataFrame.columns.map(\.name)
    guard existingColumnNames.contains("SA01VALUE") else {
        fatalError("Missing 'SA01VALUE' column in updatedDataFrame.")
    }
    guard existingColumnNames.contains("SA01MEASURE") else {
        fatalError("Missing 'SA01MEASURE' column in updatedDataFrame.")
    }
    
    // Retrieve columns as AnyColumn
    let sa01ValueColumn   = updatedDataFrame["SA01VALUE"]
    let sa01MeasureColumn = updatedDataFrame["SA01MEASURE"]
    
    // 4) Build a quick lookup for the columns in the new analytical DataFrame
    let columnNames = analyticalDataFrame.columns.map(\.name)
    var columnNameToIndex = [String: Int]()
    for (colIndex, name) in columnNames.enumerated() {
        columnNameToIndex[name] = colIndex
    }
    
    // 5) Prepare "variable" information
    let variablesArray = columnNames
    let variableGenerator = SAVariableGenerator()  // Provided by your code

    // For collecting the final updates and detailed calculation information
    struct Evaluation {
        let rowIndex: Int
        let columnIndex: Int
        let cellValue: Double
        let multiplierTimePeriod: Double
        let multiplierYear: Double
        let multiplierMeasure: Double
        let multiplierField: Double
        let evaluationResult: Double
    }
    
    var evaluations = [Evaluation]()
    
    //=============================================================================
    // ITERATE THROUGH VARIABLES
    //=============================================================================
    
    for variableName in variablesArray {
        
        //if variableName == "sales_this_year_current_month_actual_value" {
        //   print("hello")
        //}
        
        guard let variableDetails = variableGenerator.getVariableDetails(for: variableName) else {
            print("Skipping variable '\(variableName)': no details found.")
            continue
        }
        
        //print (validTimePeriods)
        
        
        let (fieldType, yearType, timePeriod, measureType) = variableDetails
        let strFieldType   = fieldType.rawValue
        let strYearType    = yearType.rawValue
        let strTimePeriod  = timePeriod.rawValue
        let strMeasureType = measureType.rawValue
        
        
        // We expect the new DataFrame to have a column for each variable
        guard let variableColIndex = columnNameToIndex[variableName] else {
            print("Analytical DataFrame has no column named '\(variableName)'. Skipping.")
            continue
        }
        
        //----------------------------------------------------------------------------
        // For each row, check if it meets the measure+field+timePeriod+year criteria
        //----------------------------------------------------------------------------
        for rowIndex in 0..<rowCount {
            
            let validTimePeriodValues = validTimePeriods[rowIndex].1
            let validYearValues       = validYears[rowIndex].1
            
            let multiplierTimePeriod = validTimePeriodValues.contains(strTimePeriod) ? 1.0 : 0.0
            let multiplierYear       = validYearValues.contains(strYearType)         ? 1.0 : 0.0
            
            let sa01MeasureAny = sa01MeasureColumn[rowIndex]
            let sa01Measure    = sa01MeasureAny as? String ?? ""
            
            let sa01ValueAny   = sa01ValueColumn[rowIndex]
            let sa01Value      = sa01ValueAny as? Double ?? 0.0
            
            var multiplierField   = 0.0
            var multiplierMeasure = 0.0
            
            // Attempt to parse the measure/field pair (custom function in your code)
            if let measureFieldPair = createMeasureFieldPair(from: sa01Measure) {
                let rowMeasureType = measureFieldPair.measure
                let rowFieldType   = measureFieldPair.field
                
                // Compare each row's measure/field to the variable's measure/field
                multiplierMeasure = (rowMeasureType.rawValue == strMeasureType) ? 1.0 : 0.0
                multiplierField   = (rowFieldType.rawValue   == strFieldType)   ? 1.0 : 0.0
            } else {
                multiplierMeasure = 0.0
                multiplierField   = 0.0
            }
            
            // Final condition: combine all multipliers
            let evaluationResult = multiplierTimePeriod
                                * multiplierYear
                                * multiplierMeasure
                                * multiplierField
            
            // If everything matches (evaluationResult == 1.0), store the value along with all details
            if evaluationResult == 1.0 {
                let eval = Evaluation(rowIndex: rowIndex,
                                      columnIndex: variableColIndex,
                                      cellValue: sa01Value,
                                      multiplierTimePeriod: multiplierTimePeriod,
                                      multiplierYear: multiplierYear,
                                      multiplierMeasure: multiplierMeasure,
                                      multiplierField: multiplierField,
                                      evaluationResult: evaluationResult)
                evaluations.append(eval)
            }
        }
    }
    
    //=============================================================================
    // APPLY ALL EVALUATIONS BACK TO THE ANALYTICAL DATAFRAME AND GROUP LOG DETAILS
    //=============================================================================
    
    // Dictionary to hold log lines grouped by row index.
    var resultsByRow = [Int: [String]]()
    
    for evaluation in evaluations {
        let colName = columnNames[evaluation.columnIndex]
        let rowIndex = evaluation.rowIndex
        let cellValue = evaluation.cellValue
        
        // One-line log for this evaluation
        let logLine = "Chunk \(chunkId) Row Index: \(rowIndex), Column Index: \(evaluation.columnIndex), Column Name: \(colName), Cell Value: \(cellValue)"
        
        // Append the log line to the corresponding row group
        resultsByRow[rowIndex, default: []].append(logLine)
        
        // Apply the evaluated value to the DataFrame
        var typedColumn = analyticalDataFrame[colName, Double.self]
        typedColumn[rowIndex] = cellValue
        analyticalDataFrame.replaceColumn(colName, with: typedColumn)
    }
    
    //=============================================================================
    // WRITE EACH ROW'S LOG DETAILS TO ITS OWN FILE, THEN OUTPUT A SUMMARY
    //=============================================================================

    /*
    // Directory where row files will be stored (adjust as needed)
    let directoryPath = "/Users/e2mq173/Documents/"
    
    // This string will accumulate all rows' results for the summary output.
    var fullResults = [String]()
    
    // Write each row's results to its own file.
    for rowIndex in resultsByRow.keys.sorted() {
        let rowLines = resultsByRow[rowIndex]!
        let rowContent = rowLines.joined(separator: "\n")
        
        // File name for the specific row (e.g., "result_row_0.txt")
        let fileURL = URL(fileURLWithPath: directoryPath + "result_row_\(rowIndex).txt")
        
        do {
            // Write the log lines to the file (this overwrites any previous content)
            try rowContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Results for row \(rowIndex) written to file \(fileURL.path)")
        } catch {
            print("Error writing file for row \(rowIndex): \(error)")
        }
        
        // Append the row's content to the full results
        fullResults.append("Row \(rowIndex):\n" + rowContent)
    }
    
    // Write the full results to a summary file.
    let summaryResults = fullResults.joined(separator: "\n\n")
    let summaryFileURL = URL(fileURLWithPath: directoryPath + "results_summary.txt")
    
    do {
        try summaryResults.write(to: summaryFileURL, atomically: true, encoding: .utf8)
        print("Summary results written to file \(summaryFileURL.path)")
    } catch {
        print("Error writing summary file: \(error)")
    }
    
     */

    return analyticalDataFrame
}
