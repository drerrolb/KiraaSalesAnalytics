//
//  EmptyDataFrameFactory.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 3/3/2025.
//

import Foundation
import TabularData

struct SA01Dataframe {
    
    static func create(rowCount: Int) -> DataFrame {
        // 1) Instead of a manual list, gather from AllAnalyticsDictionaries:
        let finalColumnNames = AllAnalyticsDictionaries.allKeys
        
        var df = DataFrame()
        
        // 2) Build columns
        for name in finalColumnNames {
            // Each column is a Column<Double?> with capacity = rowCount
            var col = Column<Double>(name: name, capacity: rowCount)
            for _ in 0..<rowCount {
                col.append(nil) // appended as nil
            }
            df.append(column: col)
        }
        
        return df
    }
}
