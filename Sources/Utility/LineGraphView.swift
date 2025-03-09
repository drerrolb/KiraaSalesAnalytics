//
//  LineGraphView.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 8/3/2025.
//


//
//  LineGraphView.swift
//  kiraa
//
//  Created by Errol Brandt on 8/3/2025.
//

import Cocoa

public class LineGraphView: NSView {
    /// Stores the incoming data points.
    public var dataPoints: [CGFloat] = []
    
    /// Maximum number of data points to show in the graph.
    public var maxDataPoints: Int = 60
    
    /// Thicker pinkish‑purple line by default.
    public var lineColor: NSColor = NSColor(calibratedRed: 0.85,
                                            green: 0.20,
                                            blue: 1.00,
                                            alpha: 1.00)
    
    /// Thickness of the line for a bolder look.
    public var lineWidth: CGFloat = 4.0
    
    // Round off the line caps and joints for a smoother appearance.
    private let lineCapStyle: NSBezierPath.LineCapStyle = .round
    private let lineJoinStyle: NSBezierPath.LineJoinStyle = .round
    
    // Transparent background
    override public var isOpaque: Bool { false }
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Clear background so we don't dim the scene behind it.
        NSColor.clear.setFill()
        dirtyRect.fill()
        
        guard dataPoints.count > 1 else { return }
        
        let width = bounds.width
        let height = bounds.height
        let spacing = width / CGFloat(maxDataPoints - 1)
        
        let path = NSBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = lineCapStyle
        path.lineJoinStyle = lineJoinStyle
        
        for (i, value) in dataPoints.enumerated() {
            let x = CGFloat(i) * spacing
            let y = (value / 100.0) * height
            let point = CGPoint(x: x, y: y)
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.line(to: point)
            }
        }
        
        lineColor.setStroke()
        path.stroke()
    }
    
    /// Adds a new data point and triggers a redraw.
    public func addDataPoint(_ value: CGFloat) {
        dataPoints.append(value)
        if dataPoints.count > maxDataPoints {
            dataPoints.removeFirst()
        }
        self.needsDisplay = true
    }
}
