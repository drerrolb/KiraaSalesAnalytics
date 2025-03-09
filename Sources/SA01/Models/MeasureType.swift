//
//  MeasureType.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 28/2/2025.
//

import Foundation


enum MeasureType: String, CustomStringConvertible, CaseIterable {
    case actual = "actual"
    case budget = "budget"
    case lockedforecast = "lockedforecast"
    case unlockedforecast = "unlockedforecast"

    var description: String { self.rawValue }
    
    var intValue: Int32 {
        switch self {
        case .actual: return 10
        case .budget: return 20
        case .lockedforecast: return 30
        case .unlockedforecast: return 31
        }
    }
}
