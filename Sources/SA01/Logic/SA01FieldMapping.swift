//
//  FeatureType.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 21/2/2025.
//


import Foundation



// MARK: - Enums for Data Classification

enum FeatureType: String, CustomStringConvertible, CaseIterable {
    case title = "title"
    case article = "article"
    
    var description: String { self.rawValue }
    
    var intValue: Int32 {
        switch self {
        case .title: return 10
        case .article: return 20
        }
    }
}

enum VariableType: String, CustomStringConvertible, CaseIterable {
    case calendar = "calendar"
    case financial = "financial"
    
    var description: String { self.rawValue }
    
    var intValue: Int32 {
        switch self {
        case .calendar: return 1
        case .financial: return 2
        }
    }
}

enum DataType: String, CustomStringConvertible, CaseIterable {
    case sales = "sales"
    case margin = "margin"
    case volume = "volume"
    case unit = "unit"

    var description: String { self.rawValue }
    
    var intValue: Int32 {
        switch self {
        case .sales: return 10
        case .margin: return 20
        case .volume: return 30
        case .unit: return 40        }
    }
}










struct Sales: Codable {
    let calendar: CalendarSales?
    let financial: FinancialSales?
}

struct CalendarSales: Codable {
    let current: PeriodSales?
    let prior: PeriodSales?
    let rolling: RollingSales?
    let months: [String: MonthSales]?
}

struct FinancialSales: Codable {
    let periods: [String: PeriodSales]?
}

struct PeriodSales: Codable {
    let month: SalesValues?
    let ytd: SalesValues?
    let ytg: SalesValues?
    let fy: SalesValues?
    let actual: String?
    let budget: String?
}

struct RollingSales: Codable {
    let R03: SalesValues?
    let R06: SalesValues?
    let R12: SalesValues?
}

struct MonthSales: Codable {
    let actual: String?
    let budget: String?
    let ytd: SalesValues?
}

struct SalesValues: Codable {
    let actual: String?
    let budget: String?
}

struct RootData: Codable {
    let this_year: Sales?
    let last_year: Sales?
    let next_year: Sales?
}








// MARK: - Field Metadata and Mapping Classes

struct FieldMetadata {
    let variableName: String
    let fieldType: FieldType
    let yearType: YearType
    let measureType: MeasureType
}

// MARK: - Field Mapping

class SA01FieldMapping {
    
    private let mappings: [String: FieldMetadata]
    
    init(mappings: [String: FieldMetadata]) {
        self.mappings = mappings
    }
    
    func getMapping(for propertyName: String) -> FieldMetadata? {
        return mappings[propertyName]
    }
    
    func getAllMappings() -> [String: FieldMetadata] {
        return mappings
    }
    
    func getAllVariableMappings() -> [String: String] {
        var variableMappings: [String: String] = [:]
        for (key, metadata) in mappings {
            variableMappings[key] = metadata.variableName
        }
        return variableMappings
    }
    
    static func generateDefaultMapping(from variableList: [String: [String: Any]]) -> SA01FieldMapping {
        var mappings: [String: FieldMetadata] = [:]
        
        for (variableName, variableDict) in variableList {
            guard let fieldTypeStr = variableDict["fieldType"] as? String,
                  let yearTypeStr = variableDict["yearType"] as? String,
                  let measureTypeStr = variableDict["measureType"] as? String else {
                continue
            }
            
            let fieldType: FieldType
            switch fieldTypeStr {
            case "sales":       fieldType = .sales
            case "margin":      fieldType = .margin
            case "volume":      fieldType = .volume
            case "unit":        fieldType = .unit
            case "call":        fieldType = .call
            case "meeting":     fieldType = .meeting
            case "proposal":    fieldType = .proposal
            case "deal":        fieldType = .deal
            default:
                continue
            }
            
            let yearType: YearType
            switch yearTypeStr {
            case "this_year":   yearType = .thisCalendarYear
            case "last_year":   yearType = .lastCalendarYear
            case "next_year":   yearType = .nextCalendarYear
            default:
                continue
            }
            
            let measureType: MeasureType
            switch measureTypeStr {
            case "actual":
                measureType = .actual
            case "budget":
                measureType = .budget
            case "lockedforecast":
                measureType = .lockedforecast
            case "unlockedforecast":
                measureType = .unlockedforecast

            default:
                continue
            }
            
            let fieldMetadata = FieldMetadata(variableName: variableName,
                                              fieldType: fieldType,
                                              yearType: yearType,
                                              measureType: measureType)
            mappings[variableName] = fieldMetadata
        }
        
        return SA01FieldMapping(mappings: mappings)
    }
    
    
    
}
