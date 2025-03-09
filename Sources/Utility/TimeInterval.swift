//
//  Time.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 21/2/2025.
//
import Foundation


// Helper function to format a TimeInterval as HH:MM:SS.
public func formatTimeInterval(_ interval: TimeInterval) -> String {
    let totalSeconds = Int(interval)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}
