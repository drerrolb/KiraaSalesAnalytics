import Foundation
import TabularData

func SA01Analysis(
    dataframe: DataFrame,
    strProcessDate: String,
    fiscalOffset: Int,
    chunkId: Int
) -> DataFrame {

    // Make a mutable copy so we can add columns safely.
    var updatedDataframe = dataframe
    let rowCount = updatedDataframe.rows.count
    
    // Dictionary: key = composite column name, value = array of source field names
    let compositeNames: [String: [String]] = [
        "SA01F01F11": ["SA01F01", "SA01F11"],
        "SA01F02F03": ["SA01F02", "SA01F03"],
        "SA01F02F04": ["SA01F02", "SA01F04"],
        "SA01F03F02": ["SA01F03", "SA01F02"],
        "SA01F03F04": ["SA01F03", "SA01F04"],
        "SA01F03F07": ["SA01F03", "SA01F07"],
        "SA01F03F16": ["SA01F03", "SA01F16"],
        "SA01F03F17": ["SA01F03", "SA01F17"],
        "SA01F04F02": ["SA01F04", "SA01F02"],
        "SA01F04F03": ["SA01F04", "SA01F03"],
        "SA01F06F07": ["SA01F06", "SA01F07"],
        "SA01F06F08": ["SA01F06", "SA01F08"],
        "SA01F06F12": ["SA01F06", "SA01F12"],
        "SA01F06F17": ["SA01F06", "SA01F17"],
        "SA01F07F03": ["SA01F07", "SA01F03"],
        "SA01F07F06": ["SA01F07", "SA01F06"],
        "SA01F08F06": ["SA01F08", "SA01F06"],
        "SA01F11F01": ["SA01F11", "SA01F01"],
        "SA01F12F06": ["SA01F12", "SA01F06"],
        "SA01F16F03": ["SA01F16", "SA01F03"],
        "SA01F16F17": ["SA01F16", "SA01F17"],
        "SA01F17F03": ["SA01F17", "SA01F03"],
        "SA01F17F06": ["SA01F17", "SA01F06"],
        "SA01F17F16": ["SA01F17", "SA01F16"]
    ]
    
    // Step 1: Create composite columns with default value "[None]"
    var newCompositeColumns = [String: Column<String>]()
    for (compositeName, _) in compositeNames {
        let defaultValues = Array(repeating: "[None]", count: rowCount)
        let column = Column<String>(name: compositeName, contents: defaultValues)
        newCompositeColumns[compositeName] = column
    }
    
    // populate the cells with concatenated values
    
    for (index, row) in updatedDataframe.rows.enumerated() {
        for (compositeName, sourceFields) in compositeNames {
            var compositeValue = ""
            for fieldName in sourceFields {
                if let fieldVal = row[fieldName] as? String {
                    if !compositeValue.isEmpty {
                        compositeValue += " "
                    }
                    compositeValue += fieldVal
                }
            }
            if !compositeValue.isEmpty {
                newCompositeColumns[compositeName]?[index] = compositeValue
            }
        }
    }
    
    // Append the composite columns to the dataframe.
    for column in newCompositeColumns.values {
        updatedDataframe.append(column: column)
    }
    
    // Now execute the main analytics function.
    let analyticalDataframe = updateDataframe(
        updatedDataframe: updatedDataframe,
        strProcessDate: strProcessDate,
        fiscalOffset: fiscalOffset,
        chunkId: chunkId)
      
    return analyticalDataframe
}
