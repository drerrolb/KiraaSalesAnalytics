//
//  ProgressTracker.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 23/2/2025.
//


actor ProgressTracker {
    private(set) var progress: Double = 0.0
    
    func updateProgress(to newProgress: Double) {
        progress = newProgress
    }
    
    func getProgress() -> Double {
        progress
    }
}