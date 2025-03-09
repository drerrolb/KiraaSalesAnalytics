//  MeasureFieldPair.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 1/3/2025.

struct MeasureFieldPair: CustomStringConvertible {
    let measure: MeasureType
    let field: FieldType

    var description: String {
        return "\(measure) \(field)"
    }
}



/// Creates a MeasureFieldPair from a two-word description string, e.g. "Actual Sales".
/// The description must match one of the valid mappings defined above.
func createMeasureFieldPair(from description: String) -> MeasureFieldPair? {
    let key = description.lowercased()
    if let mapping = validMeasureMapping[key] {
        return MeasureFieldPair(measure: mapping.0, field: mapping.1)
    } else {
        print("Invalid combination: \(description)")
        return nil
    }
}


private let validMeasureMapping: [String: (MeasureType, FieldType)] = [
    "actual sales": (.actual, .sales),
    "budget sales": (.budget, .sales),
    "locked forecast sales": (.lockedforecast, .sales),
    "unlocked forecast sales": (.unlockedforecast, .sales),
    
    "actual margin": (.actual, .margin),
    "budget margin": (.budget, .margin),
    "locked forecast margin": (.lockedforecast, .margin),
    "unlocked forecast margin": (.unlockedforecast, .margin),
    
    "actual volume": (.actual, .volume),
    "budget volume": (.budget, .volume),
    "locked forecast volume": (.lockedforecast, .volume),
    "unlocked forecast volume": (.unlockedforecast, .volume),
    
    "actual unit": (.actual, .unit),
    "budget unit": (.budget, .unit),
    "locked forecast unit": (.lockedforecast, .unit),
    "unlocked forecast unit": (.unlockedforecast, .unit),
    
    "call": (.actual, .call),
    "meeting": (.actual, .meeting),
    "proposal": (.actual, .proposal),
    "deal": (.actual, .deal),
    
]

