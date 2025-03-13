import Foundation
import os.log

class SAVariableGenerator {

    // MARK: - Variable Dictionaries
    let dictionaries: [[String: [String: String]]] = [
        
        // MARK: Actual - This Calendar Year
        ActualSalesThisCalendarYear.dictionary,
        ActualMarginThisCalendarYear.dictionary,
        ActualUnitThisCalendarYear.dictionary,
        ActualVolumeThisCalendarYear.dictionary,

        // MARK: Actual - Last Calendar Year
        ActualSalesLastCalendarYear.dictionary,
        ActualMarginLastCalendarYear.dictionary,
        ActualUnitLastCalendarYear.dictionary,
        ActualVolumeLastCalendarYear.dictionary,

        // MARK: Actual - This Financial Year
        ActualSalesThisFinancialYear.dictionary,
        ActualMarginThisFinancialYear.dictionary,
        ActualUnitThisFinancialYear.dictionary,
        ActualVolumeThisFinancialYear.dictionary,

        // MARK: Actual - Last Financial Year
        ActualSalesLastFinancialYear.dictionary,
        ActualMarginLastFinancialYear.dictionary,
        ActualUnitLastFinancialYear.dictionary,
        ActualVolumeLastFinancialYear.dictionary,

        // MARK: Budget - This Calendar Year
        BudgetSalesThisCalendarYear.dictionary,
        BudgetMarginThisCalendarYear.dictionary,
        BudgetUnitThisCalendarYear.dictionary,
        BudgetVolumeThisCalendarYear.dictionary,

        // MARK: Budget - Next Calendar Year
        BudgetSalesNextCalendarYear.dictionary,

        // MARK: Budget - This Financial Year
        BudgetSalesThisFinancialYear.dictionary,
        BudgetMarginThisFinancialYear.dictionary,
        BudgetUnitThisFinancialYear.dictionary,
        BudgetVolumeThisFinancialYear.dictionary,

        // MARK: Budget - Next Financial Year
        BudgetSalesNextFinancialYear.dictionary,

        // MARK: Forecast - This Calendar Year
        LockedForecastSalesThisCalendarYear.dictionary,
        UnlockedforecastSalesThisCalendarYear.dictionary,

        // MARK: Forecast - Next Calendar Year
        LockedforecastSalesNextCalendarYear.dictionary,
        UnlockedforecastSalesNextCalendarYear.dictionary,

        // MARK: Activities - This Calendar Year
        ActualCallThisCalendarYear.dictionary,
        ActualMeetingThisCalendarYear.dictionary,
        ActualProposalThisCalendarYear.dictionary,
        ActualDealThisCalendarYear.dictionary
    ]
    
    // Merge all dictionaries, overriding collisions by taking the second dictionary’s value.
    private let validVariableNames: [String: [String: String]]
    
    init() {
        validVariableNames = dictionaries.reduce([String: [String: String]]()) {
            $0.merging($1) { $1 }
        }
    }
    
    func printAllVariables() {
        // Local helper function to pad (or truncate) a string to a fixed length.
        func padded(_ str: String, toLength length: Int) -> String {
            if str.count < length {
                return str + String(repeating: " ", count: length - str.count)
            } else {
                return String(str.prefix(length))
            }
        }
        
        let totalWidth = 100
        let col1Width = 40
        let col2Width = totalWidth - col1Width - 3
        
        // Print header.
        let header1 = padded("Variable Name", toLength: col1Width)
        let header2 = padded("Definition", toLength: col2Width)
        
        print("\nValid Variable Names and Definitions:")
        print(header1 + " | " + header2)
        print(String(repeating: "-", count: totalWidth))
        
        // Sort the variables by name and then print each variable and its definition in one row.
        for (variable, definition) in validVariableNames.sorted(by: { $0.key < $1.key }) {
            let defString = definition.map { "\($0.value)" }
                                        .joined(separator: ", ")
            let varPadded = padded(variable, toLength: col1Width)
            let defPadded = padded(defString, toLength: col2Width)
            print(varPadded + " | " + defPadded)
        }
        
        print(String(repeating: "-", count: totalWidth))
        print("Total variables: \(validVariableNames.count)")
    }
    
    // MARK: - Retrieve Variables
    func getVariables(limit: Int? = 0) -> [String: [String: String]] {
        if validVariableNames.isEmpty {
            print("No variables loaded. Ensure the variable definitions are provided.")
        }
        
        // If limit is nil or zero, return all variables.
        guard let limit = limit, limit > 0 else {
            return validVariableNames
        }
        
        // Convert the prefix to an Array to satisfy the Dictionary initializer.
        let limitedElements = Array(validVariableNames.prefix(limit))
        return Dictionary(uniqueKeysWithValues: limitedElements)
    }
    
    // MARK: - Time Period Validation
    /// Returns 1 if the variable's required time period matches the provided date member, otherwise 0.
    func isTimePeriodValid(for variableName: String, validDateMember: String) -> Int {
        guard let details = validVariableNames[variableName],
              let requiredTimePeriod = details["TimePeriod"] else {
            print("Variable \(variableName) is not defined or missing a TimePeriod.")
            return 0
        }
        return requiredTimePeriod == validDateMember ? 1 : 0
    }
    
    // MARK: - Get Variable Details
    /// Returns a tuple containing the FieldType, YearType, TimePeriod, and MeasureType values for the given variable name.
    func getVariableDetails(for variableName: String) -> (FieldType, YearType, TimePeriod, MeasureType)? {
        // First, retrieve the details from the dictionary.
        guard let details = validVariableNames[variableName],
              let fieldTypeString = details["FieldType"],
              let yearTypeString = details["YearType"],
              let timePeriodString = details["TimePeriod"],
              let measureTypeString = details["MeasureType"]
        else {
            print("Invalid variable name or mapping for \(variableName)")
            return nil
        }
        
        // Print the raw string values.
        //print("Variable: \(variableName)")
        //print("  FieldType: \(fieldTypeString)")
        //print("  YearType: \(yearTypeString)")
       // print("  TimePeriod: \(timePeriodString)")
        //print("  MeasureType: \(measureTypeString)")
        
        // Convert the string values to enum cases.
        guard let fieldType = FieldType(rawValue: fieldTypeString),
              let yearType = YearType(rawValue: yearTypeString),
              let timePeriod = TimePeriod(rawValue: timePeriodString),
              let measureType = MeasureType(rawValue: measureTypeString)
        else {
            print("Invalid enum mapping for \(variableName)")
            return nil
        }
        
        return (fieldType, yearType, timePeriod, measureType)
    }
}
