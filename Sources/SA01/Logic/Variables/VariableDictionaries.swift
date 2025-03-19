//
//  AllAnalyticsDictionaries.swift
//  kiraa-sales-analytics
//
//  Created by You on 3/3/2025.
//
import Foundation

// MARK: - Master collector of all [String: [String: String]] dictionaries

struct AllAnalyticsDictionaries {
    
    /// Merge all the dictionaries from every file into one dictionary.
    static let allDictionaries: [String: [String: String]] = {
        
        var combined = [String: [String: String]]()
        
        // ---------- CALENDAR: LAST YEAR / ACTUAL ----------
        combined.merge(ActualVolumeLastCalendarYear.dictionary) { (_, new) in new }
        combined.merge(ActualMarginLastCalendarYear.dictionary) { (_, new) in new }
        combined.merge(ActualSalesLastCalendarYear.dictionary) { (_, new) in new }
        combined.merge(ActualUnitLastCalendarYear.dictionary) { (_, new) in new }
        
        // ---------- CALENDAR: THIS YEAR / ACTUAL ----------
        combined.merge(ActualSalesThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(ActualProposalThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(ActualCallThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(ActualUnitThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(ActualMarginThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(ActualVolumeThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(ActualDealThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(ActualMeetingThisCalendarYear.dictionary) { (_, new) in new }
        
        // ---------- CALENDAR: THIS YEAR / FORECAST ----------
        combined.merge(LockedForecastSalesThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(LockedForecastMarginThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(LockedForecastUnitThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(LockedForecastVolumeThisCalendarYear.dictionary) { (_, new) in new }
        
        
        combined.merge(UnlockedForecastSalesThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(UnlockedForecastMarginThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(UnlockedForecastUnitThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(UnlockedForecastVolumeThisCalendarYear.dictionary) { (_, new) in new }

        
        // ---------- CALENDAR: THIS YEAR / BUDGET ----------
        combined.merge(BudgetVolumeThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(BudgetSalesThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(BudgetUnitThisCalendarYear.dictionary) { (_, new) in new }
        combined.merge(BudgetMarginThisCalendarYear.dictionary) { (_, new) in new }
        
        // ---------- CALENDAR: NEXT YEAR ----------
        // Merge next-year unlocked & locked forecast, budget
        combined.merge(UnlockedForecastSalesNextCalendarYear.dictionary) { (_, new) in new }
        combined.merge(LockedforecastSalesNextCalendarYear.dictionary) { (_, new) in new }
        
        
        combined.merge(BudgetSalesNextCalendarYear.dictionary) { (_, new) in new }
        
        // ---------- FINANCIAL: LAST YEAR / ACTUAL ----------
        combined.merge(ActualVolumeLastFinancialYear.dictionary) { (_, new) in new }
        combined.merge(ActualUnitLastFinancialYear.dictionary) { (_, new) in new }
        combined.merge(ActualSalesLastFinancialYear.dictionary) { (_, new) in new }
        combined.merge(ActualMarginLastFinancialYear.dictionary) { (_, new) in new }
        
        // ---------- FINANCIAL: THIS YEAR / ACTUAL ----------
        combined.merge(ActualMarginThisFinancialYear.dictionary) { (_, new) in new }
        combined.merge(ActualVolumeThisFinancialYear.dictionary) { (_, new) in new }
        combined.merge(ActualUnitThisFinancialYear.dictionary) { (_, new) in new }
        combined.merge(ActualSalesThisFinancialYear.dictionary) { (_, new) in new }
        
        // ---------- FINANCIAL: THIS YEAR / BUDGET ----------
        combined.merge(BudgetMarginThisFinancialYear.dictionary) { (_, new) in new }
        combined.merge(BudgetSalesThisFinancialYear.dictionary) { (_, new) in new }
        combined.merge(BudgetVolumeThisFinancialYear.dictionary) { (_, new) in new }
        combined.merge(BudgetUnitThisFinancialYear.dictionary) { (_, new) in new }
        
        // ---------- FINANCIAL: NEXT YEAR / BUDGET ----------
        combined.merge(BudgetSalesNextFinancialYear.dictionary) { (_, new) in new }
        
        // Define the file URL.
        // This example writes to the Documents directory with the file name "combined.json".
        //let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        //let fileURL = documentsDirectory.appendingPathComponent("combined.json")

       // do {
            // Convert the combined dictionary to JSON data.
        //    let jsonData = try JSONSerialization.data(withJSONObject: combined, options: .prettyPrinted)
            
            // Write the JSON data to the file.
      //      try jsonData.write(to: fileURL)
      //      print("Combined data successfully written to \(fileURL.path)")
      //  } catch {
      //      print("Error writing combined data to file: \(error)")
     //   }

        
        
        return combined
    }()
    
    /// A sorted list of **all** keys from all those merged dictionaries.
    static var allKeys: [String] {
        return Array(allDictionaries.keys).sorted()
    }
    
    /// Utility function to print them in a Swift array-literal format, if desired.
    static func printAllKeysAsArrayLiteral() {
        print("let finalColumnNames = [")
        for key in allKeys {
            print("    \"\(key)\",")
        }
        print("]")
    }
}
