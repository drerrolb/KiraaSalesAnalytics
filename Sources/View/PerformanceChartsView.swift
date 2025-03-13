//
//  PerformanceChartsView.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 13/3/2025.
//


import SwiftUI
import AppKit

// MARK: - PerformanceChartsView (NSViewRepresentable for macOS)
struct PerformanceChartsView: NSViewRepresentable {
    
    // A coordinator that manages the timer and updates the graphs
    @MainActor
    class Coordinator {
        var timer: Timer?
        weak var cpuGraphView: LineGraphView?
        weak var memGraphView: LineGraphView?
        
        // Timer callback fired every 1 second
        @objc func updateLineGraphs() {
            let cpuUsage = getSystemCPUUsage()
            let memUsage = getSystemMemoryUsage()
            
            cpuGraphView?.addDataPoint(cpuUsage)
            memGraphView?.addDataPoint(memUsage)
        }
    }
    
    // Create Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // Create the NSView containing two LineGraphViews in a vertical stack
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        
        // Use an NSStackView for vertical layout
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Create the CPU usage line graph view
        let cpuGraph = LineGraphView(frame: .zero)
        cpuGraph.translatesAutoresizingMaskIntoConstraints = false
        cpuGraph.lineColor = NSColor.systemBlue // Blue for CPU usage
        stackView.addArrangedSubview(cpuGraph)
        
        // Create the Memory usage line graph view
        let memGraph = LineGraphView(frame: .zero)
        memGraph.translatesAutoresizingMaskIntoConstraints = false
        memGraph.lineColor = NSColor.systemGreen // Green for memory usage
        stackView.addArrangedSubview(memGraph)
        
        // Store references in the coordinator
        context.coordinator.cpuGraphView = cpuGraph
        context.coordinator.memGraphView = memGraph
        
        // Schedule the timer (1 second interval)
        context.coordinator.timer = Timer.scheduledTimer(timeInterval: 1.0,
                                                         target: context.coordinator,
                                                         selector: #selector(Coordinator.updateLineGraphs),
                                                         userInfo: nil,
                                                         repeats: true)
        print("Started CPU & Memory charts update timer at 1 FPS.")
        
        return containerView
    }
    
    // Update method if needed
    func updateNSView(_ nsView: NSView, context: Context) {
        // Additional dynamic updates if needed
    }
    
    // Clean up
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.timer?.invalidate()
    }
}