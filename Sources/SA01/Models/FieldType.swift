//
//  FieldType.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 28/2/2025.
//

import Foundation

enum FieldType: String, CustomStringConvertible, CaseIterable {
    case sales = "sales"
    case margin = "margin"
    case volume = "volume"
    case unit = "unit"
    case call = "call"
    case meeting = "meeting"
    case proposal = "proposal"
    case deal = "deal"

    var description: String {
        return self.rawValue
    }

    var intValue: Int {
        switch self {
        case .sales: return 10
        case .margin: return 20
        case .volume: return 30
        case .unit: return 40
        case .call: return 50
        case .meeting: return 60
        case .proposal: return 70
        case .deal: return 80
        }
    }
}
