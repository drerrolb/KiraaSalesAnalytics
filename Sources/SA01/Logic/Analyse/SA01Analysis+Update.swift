import Foundation
import TabularData

// Encapsulate mapping information and transformation logic.
struct FieldMapping {
    let analyticalFeature: String
    let sourceColumn: String
    let enabled: Bool
    let titleTransform: (String) -> String
    let articleTransform: (String) -> String
}

// -----------------------
// updateDataframe Function
// -----------------------
func updateDataframe(updatedDataframe: DataFrame, strProcessDate: String, fiscalOffset: Int, chunkId: Int) -> DataFrame {
    
    // Setup date formatter.
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    let strProcessDay = strProcessDate + "01"
    
    // Validate and parse the process date.
    guard let _ = dateFormatter.date(from: strProcessDay) else {
        print("/n*** Invalid process date \(strProcessDay).")
        return DataFrame()
    }
    
    // Extract the SA01DATE values as UInt32.
    let dateCodes: [UInt32] = updatedDataframe["SA01DATE"].compactMap { element in
        if let code = element as? UInt32 {
            return code
        } else if let strCode = element as? String, let code = UInt32(strCode) {
            return code
        }
        return nil
    }
    
    // Convert the process date string to UInt32.
    guard let processDayUInt = UInt32(strProcessDay) else {
        print("Invalid process date format for UInt32 conversion")
        return DataFrame()
    }
    

    
    // Compute valid time periods.
    let financialOffsetUInt = UInt32(fiscalOffset)
    let validTimeperiod = processTimeperiodWithMetal(
        dateCodes: dateCodes,
        processDate: processDayUInt,
        financialOffset: financialOffsetUInt
    )
    
    
    let validYear = processYearWithMetal(
        dateCodes: dateCodes,
        processDate: processDayUInt,
        financialOffset: financialOffsetUInt
    )

    
    // Generate the analytical DataFrame.
    var analyticalDataframe = generateAnalyticalDataFrame(
        updatedDataFrame: updatedDataframe,
        validTimePeriods: validTimeperiod,
        validYears: validYear,
        chunkId: chunkId
    )
    
    // Retrieve the row count from the analytical DataFrame.
    let analyticalRowCount = analyticalDataframe.rows.count
    
    // Get the available column names from the updatedDataframe.
    let availableColumnNames = updatedDataframe.columns.map { $0.name }
    
    // Define default transformation closures.
    let defaultTitleTransform: (String) -> String = { rawValue in

        let pattern = "[^ -~]|[<>\"'&;]"
        
        let cleanedString = rawValue.replacingOccurrences(
            of: pattern,
            with: "",
            options: .regularExpression
        )
        
        return cleanedString
    }
    
    
    let defaultArticleTransform: (String) -> String = { fieldContent in
        // Ensure the fieldContent only contains [a-zA-Z0-9].
        let pattern = "[^a-zA-Z0-9]"
        let cleanedString = fieldContent.replacingOccurrences(
            of: pattern,
            with: "_",
            options: .regularExpression
        )
        
        // Incorporate the cleaned string into the final format.
        return "[[prefix:\(cleanedString)|\(fieldContent)]]"
    }
    // Fully articulated base field mappings.
    // Active fields: enabled true; Spare fields: enabled false.
    let mappings: [FieldMapping] = [
        FieldMapping(analyticalFeature: "division", sourceColumn: "SA01F01", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerID", sourceColumn: "SA01F02", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerName", sourceColumn: "SA01F03", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerParent", sourceColumn: "SA01F04", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "registration", sourceColumn: "SA01F05", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "segment", sourceColumn: "SA01F06", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "accountManager", sourceColumn: "SA01F07", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "salesManager", sourceColumn: "SA01F08", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "region", sourceColumn: "SA01F09", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "postcode", sourceColumn: "SA01F10", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "country", sourceColumn: "SA01F11", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "location", sourceColumn: "SA01F12", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "currency", sourceColumn: "SA01F13", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "channel", sourceColumn: "SA01F14", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "productID", sourceColumn: "SA01F15", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "productName", sourceColumn: "SA01F16", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "productGroup", sourceColumn: "SA01F17", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "productMeasure", sourceColumn: "SA01F18", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "productRoute", sourceColumn: "SA01F19", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "productRecipe", sourceColumn: "SA01F20", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerLocality", sourceColumn: "SA01F21", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerLatitude", sourceColumn: "SA01F22", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerLongitude", sourceColumn: "SA01F23", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerTimezone", sourceColumn: "SA01F24", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerSA1", sourceColumn: "SA01F25", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerSA2", sourceColumn: "SA01F26", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerSA3", sourceColumn: "SA01F27", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerSA4", sourceColumn: "SA01F28", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerGCCSA", sourceColumn: "SA01F29", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerLGA", sourceColumn: "SA01F30", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F31", sourceColumn: "SA01F31", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F32", sourceColumn: "SA01F32", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F33", sourceColumn: "SA01F33", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F34", sourceColumn: "SA01F34", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F35", sourceColumn: "SA01F35", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F36", sourceColumn: "SA01F36", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F37", sourceColumn: "SA01F37", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F38", sourceColumn: "SA01F38", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F39", sourceColumn: "SA01F39", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F40", sourceColumn: "SA01F40", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F41", sourceColumn: "SA01F41", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F42", sourceColumn: "SA01F42", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F43", sourceColumn: "SA01F43", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F44", sourceColumn: "SA01F44", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F45", sourceColumn: "SA01F45", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F46", sourceColumn: "SA01F46", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F47", sourceColumn: "SA01F47", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F48", sourceColumn: "SA01F48", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F49", sourceColumn: "SA01F49", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F50", sourceColumn: "SA01F50", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F51", sourceColumn: "SA01F51", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F52", sourceColumn: "SA01F52", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F53", sourceColumn: "SA01F53", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F54", sourceColumn: "SA01F54", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F55", sourceColumn: "SA01F55", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F56", sourceColumn: "SA01F56", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F57", sourceColumn: "SA01F57", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F58", sourceColumn: "SA01F58", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F59", sourceColumn: "SA01F59", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F60", sourceColumn: "SA01F60", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F61", sourceColumn: "SA01F61", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F62", sourceColumn: "SA01F62", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F63", sourceColumn: "SA01F63", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F64", sourceColumn: "SA01F64", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F65", sourceColumn: "SA01F65", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F66", sourceColumn: "SA01F66", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F67", sourceColumn: "SA01F67", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F68", sourceColumn: "SA01F68", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F69", sourceColumn: "SA01F69", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F70", sourceColumn: "SA01F70", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F71", sourceColumn: "SA01F71", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F72", sourceColumn: "SA01F72", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F73", sourceColumn: "SA01F73", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F74", sourceColumn: "SA01F74", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F75", sourceColumn: "SA01F75", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F76", sourceColumn: "SA01F76", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F77", sourceColumn: "SA01F77", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F78", sourceColumn: "SA01F78", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F79", sourceColumn: "SA01F79", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F80", sourceColumn: "SA01F80", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F81", sourceColumn: "SA01F81", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F82", sourceColumn: "SA01F82", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F83", sourceColumn: "SA01F83", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F84", sourceColumn: "SA01F84", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F85", sourceColumn: "SA01F85", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F86", sourceColumn: "SA01F86", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F87", sourceColumn: "SA01F87", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F88", sourceColumn: "SA01F88", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F89", sourceColumn: "SA01F89", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F90", sourceColumn: "SA01F90", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F91", sourceColumn: "SA01F91", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F92", sourceColumn: "SA01F92", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F93", sourceColumn: "SA01F93", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F94", sourceColumn: "SA01F94", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F95", sourceColumn: "SA01F95", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F96", sourceColumn: "SA01F96", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F97", sourceColumn: "SA01F97", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F98", sourceColumn: "SA01F98", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "Spare_F99", sourceColumn: "SA01F99", enabled: false, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "division_country", sourceColumn: "SA01F01F11", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerID_customerName", sourceColumn: "SA01F02F03", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerID_customerParent", sourceColumn: "SA01F02F04", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerName_customerID", sourceColumn: "SA01F03F02", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerName_customerParent", sourceColumn: "SA01F03F04", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customer_accountmanager", sourceColumn: "SA01F03F07", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerName_productName", sourceColumn: "SA01F03F16", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerName_productGroup", sourceColumn: "SA01F03F17", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerParent_customerID", sourceColumn: "SA01F04F02", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "customerParent_customerName", sourceColumn: "SA01F04F03", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "segment_accountManager", sourceColumn: "SA01F06F07", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "segment_salesManager", sourceColumn: "SA01F06F08", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "segment_location", sourceColumn: "SA01F06F12", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "productGroup_segment", sourceColumn: "SA01F06F17", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "accountmanager_customer", sourceColumn: "SA01F07F03", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "accountManager_segment", sourceColumn: "SA01F07F06", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "salesManager_segment", sourceColumn: "SA01F08F06", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "country_division", sourceColumn: "SA01F11F01", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "location_segment", sourceColumn: "SA01F12F06", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "productName_customerName", sourceColumn: "SA01F16F03", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "productGroup_productName", sourceColumn: "SA01F16F17", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "productGroup_customerName", sourceColumn: "SA01F17F03", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "segment_productGroup", sourceColumn: "SA01F17F06", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform),
        FieldMapping(analyticalFeature: "productName_productGroup", sourceColumn: "SA01F17F16", enabled: true, titleTransform: defaultTitleTransform, articleTransform: defaultArticleTransform)
    ]
    
    
    // For each enabled mapping, derive the cell value from updatedDataframe and create two new columns.
    for mapping in mappings {
        if !mapping.enabled { continue }
        
        var titleColumnValues = [String]()
        var articleColumnValues = [String]()
        
        if !availableColumnNames.contains(mapping.sourceColumn) {
            titleColumnValues = Array(repeating: "[None]", count: analyticalRowCount)
            articleColumnValues = Array(repeating: "[None]", count: analyticalRowCount)
        } else {
            for rowIndex in 0..<analyticalRowCount {
                let rawValue: String
                if let value = updatedDataframe.rows[rowIndex][mapping.sourceColumn] as? String {
                    rawValue = value
                } else if let value = updatedDataframe.rows[rowIndex][mapping.sourceColumn] {
                    rawValue = String(describing: value)
                } else {
                    rawValue = "[None]"
                }
                titleColumnValues.append(mapping.titleTransform(rawValue))
                articleColumnValues.append(mapping.articleTransform(rawValue))
            }
        }
        let titleColumn = Column<String>(name: "title_" + mapping.analyticalFeature, contents: titleColumnValues)
        let articleColumn = Column<String>(name: "article_" + mapping.analyticalFeature, contents: articleColumnValues)
        
        // Apply columns
        analyticalDataframe.append(column: titleColumn)
        analyticalDataframe.append(column: articleColumn)
    }
    
    //let finalCSVFileURL = URL(fileURLWithPath: "/Users/e2mq173/Projects/dataframes/test.csv")
    //try? analyticalDataframe.writeCSV(to: finalCSVFileURL)
    //     print("Wrote final CSV to \(finalCSVFileURL.path)")
    
    
    return analyticalDataframe
}
