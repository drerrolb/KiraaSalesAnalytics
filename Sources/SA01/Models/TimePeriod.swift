//
//  TimePeriod.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 28/2/2025.
//

import Foundation


enum TimePeriod: String, CustomStringConvertible, CaseIterable {
    // Calendar Year Periods and Rolling Periods
    case currentCalendarMonth = "currentcalendarmonth"
    case currentCalendarYTD = "currentcalendarytd"
    case currentCalendarYTG = "currentcalendarytg"
    case currentCalendarFY = "currentcalendarfy"
    case priorCalendarMonth = "priorcalendarmonth"
    case priorCalendarYTD = "priorcalendarytd"
    case priorCalendarYTG = "priorcalendarytg"
    case priorCalendarFY = "priorcalendarfy"
    case rollingCalendarR03 = "rollingcalendarR03"
    case rollingCalendarR06 = "rollingcalendarR06"
    case rollingCalendarR12 = "rollingcalendarR12"
    
    // Financial Year Periods and Rolling Periods
    case currentFinancialPeriod = "currentfinancialperiod"
    case currentFinancialYTD = "currentfinancialytd"
    case currentFinancialYTG = "currentfinancialytg"
    case currentFinancialFY = "currentfinancialfy"
    case priorFinancialPeriod = "priorfinancialperiod"
    case priorFinancialYTD = "priorfinancialytd"
    case priorFinancialYTG = "priorfinancialytg"
    case priorFinancialFY = "priorfinancialfy"
    case rollingFinancialR03 = "rollingfinancialR03"
    case rollingFinancialR06 = "rollingfinancialR06"
    case rollingFinancialR12 = "rollingfinancialR12"
    
    // Calendar Months (Specific)
    case januarymonth = "januarymonth"
    case februarymonth = "februarymonth"
    case marchmonth = "marchmonth"
    case aprilmonth = "aprilmonth"
    case maymonth = "maymonth"
    case junemonth = "junemonth"
    case julymonth = "julymonth"
    case augustmonth = "augustmonth"
    case septembermonth = "septembermonth"
    case octobermonth = "octobermonth"
    case novembermonth = "novembermonth"
    case decembermonth = "decembermonth"
    
    // Calendar YTD Flags
    case januaryytd = "januaryytd"
    case februaryytd = "februaryytd"
    case marchytd = "marchytd"
    case aprilytd = "aprilytd"
    case mayytd = "mayytd"
    case juneytd = "juneytd"
    case julyytd = "julyytd"
    case augustytd = "augustytd"
    case septemberytd = "septemberytd"
    case octoberytd = "octoberytd"
    case novemberytd = "novemberytd"
    case decemberytd = "decemberytd"
    
    // Financial Periods (Specific)
    case p01 = "p01"
    case p02 = "p02"
    case p03 = "p03"
    case p04 = "p04"
    case p05 = "p05"
    case p06 = "p06"
    case p07 = "p07"
    case p08 = "p08"
    case p09 = "p09"
    case p10 = "p10"
    case p11 = "p11"
    case p12d = "p12"
    
    // Financial Periods YTD
    case p01ytd = "p01ytd"
    case p02ytd = "p02ytd"
    case p03ytd = "p03ytd"
    case p04ytd = "p04ytd"
    case p05ytd = "p05ytd"
    case p06ytd = "p06ytd"
    case p07ytd = "p07ytd"
    case p08ytd = "p08ytd"
    case p09ytd = "p09ytd"
    case p10ytd = "p10ytd"
    case p11ytd = "p11ytd"
    case p12ytd = "p12ytd"
    
    var description: String {
        return self.rawValue
    }
    
    /// Returns the calendar month TimePeriod for the given date.
    static func from(date: Date) -> TimePeriod? {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 1: return .januarymonth
        case 2: return .februarymonth
        case 3: return .marchmonth
        case 4: return .aprilmonth
        case 5: return .maymonth
        case 6: return .junemonth
        case 7: return .julymonth
        case 8: return .augustmonth
        case 9: return .septembermonth
        case 10: return .octobermonth
        case 11: return .novembermonth
        case 12: return .decembermonth
        default: return nil
        }
    }
    
    /// Returns the calendar YTD flag TimePeriod for the given date.
    static func fromYTD(date: Date) -> TimePeriod? {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 1: return .januaryytd
        case 2: return .februaryytd
        case 3: return .marchytd
        case 4: return .aprilytd
        case 5: return .mayytd
        case 6: return .juneytd
        case 7: return .julyytd
        case 8: return .augustytd
        case 9: return .septemberytd
        case 10: return .octoberytd
        case 11: return .novemberytd
        case 12: return .decemberytd
        default: return nil
        }
    }

}
