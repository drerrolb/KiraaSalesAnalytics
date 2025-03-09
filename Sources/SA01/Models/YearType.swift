//
//  YearType.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 28/2/2025.
//

import Foundation

// -----------------------------------------------------------------------------
// Enum Definitions
// -----------------------------------------------------------------------------
enum YearType: String, CustomStringConvertible, CaseIterable {
    // Existing cases
    case thisCalendarYear   = "thiscalyear"
    case lastCalendarYear   = "lastcalyear"
    case nextCalendarYear   = "nextcalyear"
    case thisFinancialYear  = "thisfinyear"
    case lastFinancialYear  = "lastfinyear"
    case nextFinancialYear  = "nextfinyear"
    
    // New “prior2” (year == procYear - 2) and “subseq2” (year == procYear + 2) cases
    case prior2CalendarYear = "prior2calyear"
    case prior2FinancialYear = "prior2finyear"
    case subseq2CalendarYear = "subseq2calyear"
    case subseq2FinancialYear = "subseq2finyear"
    
    var description: String {
        self.rawValue
    }
    
    // Example mapping to integer values; feel free to customize.
    var intValue: Int32 {
        switch self {
        // Existing cases
        case .thisCalendarYear:      return 10
        case .thisFinancialYear:     return 15
        case .lastCalendarYear:      return 20
        case .lastFinancialYear:     return 25
        case .nextCalendarYear:      return 30
        case .nextFinancialYear:     return 35

        // New cases
        case .prior2CalendarYear:    return  0
        case .prior2FinancialYear:   return  5
        case .subseq2CalendarYear:   return 40
        case .subseq2FinancialYear:  return 45
        }
    }
}

